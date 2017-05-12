public struct Server {
    public let tcpHost: Host
    public let middleware: [Middleware]
    public let responder: Responder
    public let failure: (Error) -> Void

    public let host: String
    public let port: Int
    public let bufferSize: Int

    public init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int = 128, reusePort: Bool = false, bufferSize: Int = 4096, middleware: [Middleware] = [], responder: ResponderRepresentable, failure: @escaping (Error) -> Void =  Server.log(error:)) throws {
        self.tcpHost = try TCPHost(
            host: host,
            port: port,
            backlog: backlog,
            reusePort: reusePort
        )
        self.host = host
        self.port = port
        self.bufferSize = bufferSize
        self.middleware = middleware
        self.responder = responder.responder
        self.failure = failure
    }

    public init(host: String = "0.0.0.0", port: Int = 8080, backlog: Int = 128, reusePort: Bool = false, bufferSize: Int = 4096, certificatePath: String, privateKeyPath: String, certificateChainPath: String? = nil, middleware: [Middleware] = [], responder: ResponderRepresentable, failure: @escaping (Error) -> Void =  Server.log(error:)) throws {
        self.tcpHost = try TCPTLSHost(
            host: host,
            port: port,
            backlog: backlog,
            reusePort: reusePort,
            certificatePath: certificatePath,
            privateKeyPath: privateKeyPath,
            certificateChainPath: certificateChainPath
        )
        self.host = host
        self.port = port
        self.bufferSize = bufferSize
        self.middleware = middleware
        self.responder = responder.responder
        self.failure = failure
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
  public func start(_ retryTimes: Int = 10, _ retryWait: Double = 5.seconds, _ readDeadline: Double = 30.seconds.fromNow(), _ serializeDeadline: Double = 5.minutes.fromNow()) throws {
        printHeader()
        try retry(times: retryTimes, waiting: retryWait) {
            while true {
                let stream = try tcpHost.accept(deadline: .never)
                co { do { try self.process(stream: stream, readDeadline, serializeDeadline) } catch { self.failure(error) } }
            }
        }
    }

  public func startInBackground(_ retryTimes: Int = 10, _ retryWait: Double = 5.seconds, _ readDeadline: Double = 30.seconds.fromNow(), _ serializeDeadline: Double = 5.minutes.fromNow()) {
        co { do { try self.start(retryTimes, retryWait, readDeadline, serializeDeadline) } catch { self.failure(error) } }
    }

  public func process(stream: Stream, _ readDeadline: Double = 30.seconds.fromNow(), _ serializeDeadline: Double = 5.minutes.fromNow()) throws {
        let buffer = UnsafeMutableBufferPointer<Byte>(capacity: bufferSize)
        defer { buffer.deallocate(capacity: bufferSize) }

        let parser = MessageParser(mode: .request)
        let serializer = ResponseSerializer(stream: stream, bufferSize: bufferSize)

        while !stream.closed {
            do {
                let bytesRead = try stream.read(into: buffer, deadline: readDeadline)
                
                for message in try parser.parse(bytesRead) {
                    let request = message as! Request
                    let response = try middleware.chain(to: responder).respond(to: request)
                    try serializer.serialize(response, deadline: serializeDeadline)
                    
                    if let upgrade = response.upgradeConnection {
                        try upgrade(request, stream)
                        stream.close()
                    }
                    
                    if !request.isKeepAlive {
                        stream.close()
                    }
                }
            } catch SystemError.brokenPipe {
                break
            } catch {
                if stream.closed {
                    break
                }
                
                let (response, unrecoveredError) = Server.recover(error: error)
                try serializer.serialize(response, deadline: .never)

                if let error = unrecoveredError {
                    stream.close()
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
        print("Zewo/HTTPServer Error: \(error)")
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
