public struct Server {
    public let tcpHost: Host
    public let middleware: [Middleware]
    public let responder: Responder
    public let failure: (Error) -> Void

    public let host: String
    public let port: Int
    public let bufferSize: Int

    public init(configuration: Server.Configuration, middleware: [Middleware] = [], responder: Responder, failure: @escaping (Error) -> Void = Server.log(error:)) throws {
        self.tcpHost = try TCPHost(configuration: configuration.tcp)
        self.middleware = middleware
        self.responder = responder
        self.failure = failure
        self.host = configuration.tcp.host
        self.port = configuration.tcp.port
        self.bufferSize = configuration.bufferSize
    }

    public init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int, reusePort: Bool = false, bufferSize: Int = 2048,  middleware: [Middleware] = [], responder: Responder, failure: @escaping (Error) -> Void =  Server.log(error:)) throws {

        try self.init(configuration: Server.Configuration.init(
                tcp: .init(
                    host: host,
                    port: port,
                    backlog: backlog,
                    reusePort: reusePort
                ),
                bufferSize: bufferSize
            ),
            middleware: middleware,
            responder: responder,
            failure: failure
        )
    }

    public init(configuration map: Map, middleware: [Middleware] = [], responder: Responder, failure: @escaping (Error) -> Void =  Server.log(error:)) throws {
        try self.init(configuration: Configuration(map: map), middleware: middleware, responder: responder, failure: failure)
    }

    public init(configuration: Map, middleware: [Middleware] = [], responder representable: ResponderRepresentable, failure: @escaping (Error) -> Void = Server.log(error:)) throws {
        try self.init(
            configuration: configuration,
            middleware: middleware,
            responder: representable.responder,
            failure: failure
        )
    }
}

func retry(times: Int, waiting duration: Double, work: (Void) throws -> Void) throws {
    var failCount = 0
    var lastError: Error!
    while failCount < times {
        do {
            try work()
        } catch {
            failCount += 1
            lastError = error
            print("Error: \(error)")
            print("Retrying in \(duration) seconds.")
            nap(for: duration)
            print("Retrying.")
        }
    }
    throw lastError
}

extension Server {
    public func start() throws {
        printHeader()
        try retry(times: 10, waiting: 5.seconds) {
            while true {
                let stream = try tcpHost.accept()
                co { do { try self.process(stream: stream) } catch { self.failure(error) } }
            }
        }
    }

    public func startInBackground() {
        co { do { try self.start() } catch { self.failure(error) } }
    }

    public func process(stream: Stream) throws {
        let parser = RequestParser(stream: stream, bufferSize: bufferSize)
        let serializer = ResponseSerializer(stream: stream, bufferSize: bufferSize)

        while !stream.closed {
            do {
                let request = try parser.parse()
                let response = try middleware.chain(to: responder).respond(to: request)
                try serializer.serialize(response)

                if let upgrade = response.upgradeConnection {
                    try upgrade(request, stream)
                    stream.close()
                }

                if !request.isKeepAlive {
                    stream.close()
                }
            } catch SystemError.brokenPipe {
                break
            } catch {
                if stream.closed {
                    break
                }

                let (response, unrecoveredError) = Server.recover(error: error)
                try serializer.serialize(response)

                if let error = unrecoveredError {
                    throw error
                }
            }
        }
    }

    private static func recover(error: Error) -> (Response, Error?) {
        guard let representable = error as? ResponseRepresentable else {
            let body = Buffer(String(describing: error))
            return (Response(status: .internalServerError, body: body), error)
        }
        return (representable.response, nil)
    }

    public static func log(error: Error) -> Void {
        print("Error: \(error)")
    }

    public func printHeader() {
        var header = "\n"
        header += "\n"
        header += "\n"
        header += "                             _____\n"
        header += "     ,.-``-._.-``-.,        /__  /  ___ _      ______\n"
        header += "    |`-._,.-`-.,_.-`|         / /  / _ \\ | /| / / __ \\\n"
        header += "    |   |ˆ-. .-`|   |        / /__/  __/ |/ |/ / /_/ /\n"
        header += "    `-.,|   |   |,.-`       /____/\\___/|__/|__/\\____/ (c)\n"
        header += "        `-.,|,.-`           -----------------------------\n"
        header += "\n"
        header += "================================================================================\n"
        header += "Started HTTP server at \(host), listening on port \(port)."
        print(header)
    }
}

extension Server {
    public struct Configuration {
        public let tcp: TCPHost.Configuration
        public let bufferSize: Int

        public init(tcp: TCPHost.Configuration = .init(), bufferSize: Int = 2048) {
            self.tcp = tcp
            self.bufferSize = bufferSize
        }
    }
}

extension Server.Configuration : MapInitializable {
    public init(map: Map) throws {
        self.bufferSize = map["bufferSize"].int ?? 2048
        self.tcp = try (map["tcp"].dictionary?.map).flatMap(TCPHost.Configuration.init(map:)) ?? .init()
    }
}
