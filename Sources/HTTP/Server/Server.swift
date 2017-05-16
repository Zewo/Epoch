import Core
import IO
import Venice

public typealias Respond = (Request) -> Response

public final class Server {
    /// Parser buffer size
    public let parserBufferSize: Int
    
    /// Serializer buffer size
    public let serializerBufferSize: Int
    
    /// Parse timeout
    public let parseTimeout: Duration
    
    /// Serialization timeout
    public let serializeTimeout: Duration
    
    /// Close connection timeout
    public let closeConnectionTimeout: Duration
    
    private let logger: Logger
    private let group = Coroutine.Group()
    private let respond: Respond

    /// Creates a new HTTP server
    public init(
        parserBufferSize: Int = 4096,
        serializerBufferSize: Int = 4096,
        parseTimeout: Duration = 5.minutes,
        serializeTimeout: Duration = 5.minutes,
        closeConnectionTimeout: Duration = 1.minute,
        logAppenders: [LogAppender] = [defaultAppender],
        respond: @escaping Respond
    ) {
        self.parserBufferSize = parserBufferSize
        self.serializerBufferSize = serializerBufferSize
        self.parseTimeout = parseTimeout
        self.serializeTimeout = serializeTimeout
        self.closeConnectionTimeout = closeConnectionTimeout
        self.logger = Logger(name: "HTTP server", appenders: logAppenders)
        self.respond = respond
    }
    
    /// Creates a new HTTP server
    public convenience init(
        parserBufferSize: Int = 4096,
        serializerBufferSize: Int = 4096,
        parseTimeout: Duration = 5.minutes,
        serializeTimeout: Duration = 5.minutes,
        closeConnectionTimeout: Duration = 1.minute,
        logAppenders: [LogAppender] = [defaultAppender],
        router: BasicRouter
    ) {
        self.init(
            parserBufferSize: parserBufferSize,
            serializerBufferSize: serializerBufferSize,
            parseTimeout: parseTimeout,
            serializeTimeout: serializeTimeout,
            closeConnectionTimeout: closeConnectionTimeout,
            logAppenders: logAppenders,
            respond: router.respond
        )
    }
    
    deinit {
        try? group.close()
    }

    /// Start server
    public func start(
        host: String = "0.0.0.0",
        port: Int = 8080,
        backlog: Int = 2048,
        reusePort: Bool = false,
        header: String = defaultHeader,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) throws {
        let tcp = try TCPHost(
            host: host,
            port: port,
            backlog: backlog,
            reusePort: reusePort
        )
        
        log(
            header: header,
            host: host,
            port: port,
            locationInfo: Logger.LocationInfo(
                file: file,
                line: line,
                column: column,
                function: function
            )
        )
        
        try start(host: tcp)
    }
    
    /// Start server
    public func start(host: Host) throws {
        while true {
            do {
                try accept(host)
            } catch SystemError.tooManyOpenFiles {
                logger.info("Too many open files while accepting connections. Retrying in 10 seconds.")
                try Coroutine.wakeUp(10.seconds.fromNow())
                continue
            } catch VeniceError.canceled {
                break
            } catch {
                logger.error("Error while accepting connections.", error: error)
                throw error
            }
        }
    }
    
    /// Stop server
    public func stop() throws {
        self.logger.info("Stopping HTTP server.")
        try group.close()
    }
    
    private static var defaultAppender: LogAppender {
        return StandardOutputAppender(name: "HTTP server", levels: [.error, .info, .debug])
    }
    
    private static var defaultHeader: String {
        var header = "\n"
        header += "                        _____                         \n"
        header += "     _.-ˆˆ-._.-ˆˆ-._   /__  /   ____ _      __ ____   \n"
        header += "    |ˆ-._.-ˆˆˆ-._.-ˆ|    / /   / __/| | /| / // __ \\ \n"
        header += "    |   |ˆ-._.-ˆ|   |   / /__ / __/ | |/ |/ // /_/ /  \n"
        header += "    ˆ-._|   |   |_.-ˆ  /____//____/ |__/|__/ \\____/  \n"
        header += "        ˆ-._|_.-ˆ                                       \n"
        header += "_______________________________________________________ \n"
        return header
    }
    
    @inline(__always)
    private func log(header: String, host: String, port: Int, locationInfo: Logger.LocationInfo) {
        var header = header
        header += "Started HTTP server at \(host), listening on port \(port)."
        logger.info(header, locationInfo: locationInfo)
    }
    
    @inline(__always)
    private func accept(_ host: Host) throws {
        let stream = try host.accept(deadline: .never)
        
        try group.addCoroutine { [unowned self] in
            do {
                try self.process(stream)
            } catch SystemError.brokenPipe {
                return
            } catch SystemError.connectionResetByPeer {
                return
            } catch VeniceError.canceled {
                return
            } catch {
                self.logger.error("Error while processing connection.", error: error)
            }
        }
    }

    @inline(__always)
    private func process(_ stream: DuplexStream) throws {
        let parser = RequestParser(stream: stream, bufferSize: parserBufferSize)
        let serializer = ResponseSerializer(stream: stream, bufferSize: serializerBufferSize)
        
        while true {
            let request = try parser.parse(deadline: parseTimeout.fromNow())
            let response = respond(request)
            let keepAlive = try serializer.serialize(response, deadline: serializeTimeout.fromNow())
            
            guard keepAlive else {
                try stream.done(deadline: closeConnectionTimeout.fromNow())
                break
            }
            
            if let upgrade = response.upgradeConnection {
                try upgrade(request, stream)
                try stream.done(deadline: closeConnectionTimeout.fromNow())
                break
            }
            
            if !request.isKeepAlive {
                try stream.done(deadline: closeConnectionTimeout.fromNow())
                break
            }
        }
    }
}
