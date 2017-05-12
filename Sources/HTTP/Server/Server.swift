import POSIX
import Core
import IO
import Venice

public typealias Respond = (Request) -> Response

public final class Server {
    /// Server buffer size
    public let bufferSize: Int
    
    /// Parse timeout
    public let parseTimeout: Duration
    
    /// Serialization timeout
    public let serializeTimeout: Duration
    
    private let logger: Logger
    private let group = Coroutine.Group()

    /// Creates a new HTTP server
    public init(
        bufferSize: Int = 4096,
        parseTimeout: Duration = 5.minutes,
        serializeTimeout: Duration = 5.minutes,
        logAppenders: [LogAppender] = [defaultAppender]
    ) {
        self.bufferSize = bufferSize
        self.parseTimeout = parseTimeout
        self.serializeTimeout = serializeTimeout
        self.logger = Logger(name: "HTTP server", appenders: logAppenders)
    }
    
    deinit {
        try? group.cancel()
    }

    /// Start server
    public func start(
        host: String = "0.0.0.0",
        port: Int = 8080,
        backlog: Int = 2048,
        reusePort: Bool = false,
        deadline: Deadline = 1.minute.fromNow(),
        header: String = defaultHeader,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column,
        respond: @escaping Respond
    ) throws {
        let tcp = try TCPHost(
            host: host,
            port: port,
            backlog: backlog,
            reusePort: reusePort,
            deadline: deadline
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
        
        try start(host: tcp, respond: respond)
    }
    
    /// Start server
    public func start(host: Host, respond: @escaping Respond) throws {
        while true {
            do {
                try accept(host, respond: respond)
            } catch SystemError.tooManyOpenFiles {
                let waitDuration = 10.seconds
                logger.info("Too many open files. Retrying in 10 seconds.")
                try Coroutine.wakeUp(waitDuration.fromNow())
                continue
            } catch VeniceError.canceledCoroutine {
                break
            }
        }
    }
    
    /// Stop server
    public func stop() throws {
        self.logger.info("Stopping HTTP server.")
        try group.cancel()
    }
    
    private static var defaultAppender: LogAppender {
        return StandardOutputAppender(name: "HTTP server", levels: [.error, .info])
    }
    
    private static var defaultHeader: String {
        var header = "\n"
        header += "   _____                                          \n"
        header += "  / ___/ ____   ____ _ _____ _____ ____  _      __\n"
        header += "  \\__ \\ / __ \\ / __ `// ___// ___// __ \\| | /| / /\n"
        header += " ___/ // /_/ // /_/ // /   / /   / /_/ /| |/ |/ / \n"
        header += "/____// .___/ \\__,_//_/   /_/    \\____/ |__/|__/  \n"
        header += "     /_/                                          \n"
        header += "--------------------------------------------------\n"
        return header
    }
    
    @inline(__always)
    private func log(header: String, host: String, port: Int, locationInfo: Logger.LocationInfo) {
        var header = header
        header += "Started HTTP server at \(host), listening on port \(port)."
        logger.info(header, locationInfo: locationInfo)
    }
    
    @inline(__always)
    private func accept(_ host: Host, respond: @escaping Respond) throws {
        let stream = try host.accept(deadline: .never)
        
        try group.addCoroutine {
            do {
                try self.process(stream, respond: respond)
            } catch SystemError.brokenPipe {
                return
            } catch SystemError.connectionResetByPeer {
                return
            } catch VeniceError.canceledCoroutine {
                return
            } catch {
                self.logger.error("HTTP Server Error", error: error)
            }
        }
    }

    @inline(__always)
    private func process(_ stream: DuplexStream, respond: @escaping Respond) throws {
        let parser = RequestParser(stream: stream, bufferSize: bufferSize)
        let serializer = ResponseSerializer(stream: stream, bufferSize: bufferSize)
        
        try parser.parse(timeout: parseTimeout) { request in
            let response = respond(request)
            try serializer.serialize(response, timeout: self.serializeTimeout)
            
            if let upgrade = response.upgradeConnection {
                try upgrade(request, stream)
                stream.close()
            }
            
            if !request.isKeepAlive {
                stream.close()
            }
        }
    }
}
