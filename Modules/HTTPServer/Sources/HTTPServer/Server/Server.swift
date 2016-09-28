public struct Server {
    public let tcpHost: Host
    public let middleware: [Middleware]
    public let responder: Responder
    public let failure: (Error) -> Void

    public let host: String
    public let port: Int
    public let bufferSize: Int

    public init(host: String = "0.0.0.0", port: Int = 8080, middleware: [Middleware] = [], responder: Responder, failure: @escaping (Error) -> Void =  Server.log(error:)) throws {
        let backlog = 128
        let reusePort = false

        let bufferSize = 2048
        let enableLog = true
        let enableSession = true
        let enableContentNegotiation = true

        self.tcpHost = try TCPHost(
            configuration: [
                "host": Map(host),
                "port": Map(port),
                "backlog": Map(backlog),
                "reusePort": Map(reusePort),
                ]
        )

        var chain: [Middleware] = []

        if enableLog {
            chain.append(LogMiddleware())
        }

        if enableSession {
            chain.append(SessionMiddleware())
        }

        if enableContentNegotiation {
            chain.append(ContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self]))
        }

        chain.append(contentsOf: middleware)

        self.host = host
        self.port = port
        self.bufferSize = bufferSize
        self.middleware = chain
        self.responder = responder
        self.failure = failure
    }

    public init(configuration: Map, middleware: [Middleware], responder: Responder, failure: @escaping (Error) -> Void =  Server.log(error:)) throws {
        let host = configuration["tcp", "host"].string ?? "0.0.0.0"
        let port = configuration["tcp", "port"].int ?? 8080
        let backlog = configuration["tcp", "backlog"].int ?? 128
        let reusePort = configuration["tcp", "reusePort"].bool ?? false

        let certificate = configuration["tls", "certificate"].string
        let privateKey = configuration["tls", "privateKey"].string
        let certificateChain = configuration["tls", "certificateChain"].string

        let bufferSize = configuration["bufferSize"].int ?? 2048
        let enableLog = configuration["log"].bool ?? true
        let enableSession = configuration["session"].bool ?? true
        let enableContentNegotiation = configuration["contentNegotiation"].bool ?? true

        if let c = certificate, let pk = privateKey {
            self.tcpHost = try TCPTLSHost(
                configuration: [
                    "host": Map(host),
                    "port": Map(port),
                    "backlog": Map(backlog),
                    "reusePort": Map(reusePort),

                    "certificate": Map(c),
                    "privateKey": Map(pk),
                    "certificateChain": Map(certificateChain),
                ]
            )
        } else {
            self.tcpHost = try TCPHost(
                configuration: [
                    "host": Map(host),
                    "port": Map(port),
                    "backlog": Map(backlog),
                    "reusePort": Map(reusePort),
                ]
            )
        }

        var chain: [Middleware] = []

        if enableLog {
            chain.append(LogMiddleware())
        }

        if enableSession {
            chain.append(SessionMiddleware())
        }

        if enableContentNegotiation {
            chain.append(ContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self]))
        }

        chain.append(contentsOf: middleware)

        self.host = host
        self.port = port
        self.bufferSize = bufferSize
        self.middleware = chain
        self.responder = responder
        self.failure = failure
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
        let chunkBytes = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { chunkBytes.deallocate(capacity: bufferSize) }
        let chunk = UnsafeMutableBufferPointer(start: chunkBytes, count: bufferSize)
        
        let parser = MessageParser(mode: .request)
        let serializer = ResponseSerializer(stream: stream, bufferSize: bufferSize)

        while !stream.closed {
            do {
                let bytesRead = try stream.read(into: chunk)
                let chunkRead = UnsafeBufferPointer(start: chunkBytes, count: bytesRead)
                
                try parser.parse(chunkRead) { message in
                    let request = message as! Request
                    let response = try middleware.chain(to: responder).respond(to: request)
                    try serializer.serialize(response)
                    
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
