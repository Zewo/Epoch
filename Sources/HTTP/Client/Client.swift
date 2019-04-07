import Core
import IO
import Venice
import struct Foundation.URL

public enum ClientError : Error {
    case schemeRequired
    case invalidScheme
    case hostRequired
}

open class Client {
    fileprivate typealias Connection = (
        stream: DuplexStream,
        serializer: RequestSerializer,
        parser: ResponseParser
    )
    
    public struct Configuration {
        /// Pool size
        public var poolSize: ClosedRange<Int> = 5 ... 10
        
        /// Parser buffer size
        public var parserBufferSize: Int = 4096
        
        /// Serializer buffer size
        public var serializerBufferSize: Int = 4096
        
        /// Address resolution timeout
        public var addressResolutionTimeout: Duration = 1.minute
        
        /// Connection timeout
        public var connectionTimeout: Duration = 1.minute
        
        /// Borrow timeout
        public var borrowTimeout: Duration = 5.minutes
        
        /// Parse timeout
        public var parseTimeout: Duration = 5.minutes
        
        /// Serialization timeout
        public var serializeTimeout: Duration = 5.minutes
        
        /// Close connection timeout
        public var closeConnectionTimeout: Duration = 1.minute
        
        public init() {}
        
        public static var `default`: Configuration {
            return Configuration()
        }
    }
    
    /// Client configuration.
    public let configuration: Configuration
    
    private let host: String
    private let port: Int
    private let pool: Pool
    
    /// Creates a new HTTP client
    public init(uri: String, configuration: Configuration = .default) throws {
        let uri = try URI(uri)
        let (host, port, secure) = try Client.extract(uri: uri)
        
        self.host = host
        self.port = port
        self.configuration = configuration
        
        self.pool = try Pool(size: configuration.poolSize) {
            let (stream, serializer, parser) = try Client.connection(
                host: host,
                port: port,
                secure: secure,
                configuration: configuration
            )
            
            return Connection(
                stream: stream,
                serializer: serializer,
                parser: parser
            )
        }
    }
    
    deinit {
        pool.close()
    }
    
    private static func extract(uri: URI) throws -> (String, Int, Bool) {
        var secure = true
        
        guard let scheme = uri.scheme else {
            throw ClientError.schemeRequired
        }
        
        switch scheme {
        case "https":
            secure = true
        case "http":
            secure = false
        default:
            throw ClientError.invalidScheme
        }
        
        guard let host = uri.host else {
            throw ClientError.hostRequired
        }
        
        let port = uri.port ?? (secure ? 443 : 80)
        
        return (host, port, secure)
    }
    
    private static func connection(
        host: String,
        port: Int,
        secure: Bool,
        configuration: Configuration
    ) throws -> (DuplexStream, RequestSerializer, ResponseParser) {
        let stream: DuplexStream
        
        if secure {
            stream = try TLSStream(
                host: host,
                port: port,
                deadline: configuration.addressResolutionTimeout.fromNow()
            )
        } else {
            stream = try TCPStream(
                host: host,
                port: port,
                deadline: configuration.addressResolutionTimeout.fromNow()
            )
        }
        
        try stream.open(deadline: configuration.connectionTimeout.fromNow())
        
        let serializer = RequestSerializer(
            stream: stream,
            bufferSize: configuration.serializerBufferSize
        )
        
        let parser = ResponseParser(
            stream: stream,
            bufferSize: configuration.parserBufferSize
        )
        
        return (stream, serializer, parser)
    }
    
    private static func configureHeaders(
        request: Request,
        host: String,
        port: Int,
        closeConnection: Bool = false
    ) {
        if request.host == nil {
            request.host = host + ":" + port.stringValue
        }
        
        if request.userAgent == nil {
            request.userAgent = "Zewo"
        }
        
        if closeConnection {
            request.connection = "close"
        }
    }
    
    public static func send(_ request: Request, configuration: Configuration = .default) throws -> Response {
        let (host, port, secure) = try extract(uri: request.uri)
        
        let (stream, serializer, parser) = try connection(
            host: host,
            port: port,
            secure: secure,
            configuration: configuration
        )
        
        configureHeaders(
            request: request,
            host: host,
            port: port,
            closeConnection: true
        )
        
        try serializer.serialize(
            request,
            deadline: configuration.serializeTimeout.fromNow()
        )
        
        let response = try parser.parse(
            deadline: configuration.parseTimeout.fromNow()
        )
        
        if let upgrade = request.upgradeConnection {
            try upgrade(response, stream)
        }
        
        try stream.close(deadline: configuration.closeConnectionTimeout.fromNow())
        return response
    }
    
    public func send(_ request: Request) throws -> Response {
        var retryCount = 0
        
        loop: while true {
            let connection = try pool.borrow(
                deadline: configuration.borrowTimeout.fromNow()
            )
            
            let stream = connection.stream
            let serializer = connection.serializer
            let parser = connection.parser
            
            Client.configureHeaders(request: request, host: host, port: port)
            
            do {
                try serializer.serialize(
                    request,
                    deadline: configuration.serializeTimeout.fromNow()
                )
                
                let response = try parser.parse(
                    deadline: configuration.parseTimeout.fromNow()
                )
                
                if let upgrade = request.upgradeConnection {
                    try upgrade(response, stream)
                    try stream.close(deadline: configuration.closeConnectionTimeout.fromNow())
                    pool.dispose(connection)
                } else {
                    pool.return(connection)
                }
                
                return response
            } catch {
                pool.dispose(connection)
                retryCount += 1
                
                guard retryCount < 10 else {
                    throw error
                }
                
                continue loop
            }
        }
    }
}

fileprivate class Pool {
    fileprivate var size: ClosedRange<Int>
    fileprivate var borrowed = 0
    fileprivate var available: [Client.Connection] = []
    fileprivate var waitList: Channel<Void>
    fileprivate var waiting: Int = 0
    
    fileprivate let create: () throws -> Client.Connection
    
    fileprivate init(
        size: ClosedRange<Int>,
        _ create: @escaping () throws -> Client.Connection
    ) throws {
        self.size = size
        self.create = create
        
        waitList = try Channel()
        
        for _ in 0 ..< size.lowerBound {
            let connection = try create()
            self.available.append(connection)
        }
    }
    
    fileprivate func close() {
        let deadline = 30.seconds.fromNow()
        
        for connection in available {
            try? connection.stream.close(deadline: deadline)
        }
    }
    
    fileprivate func `return`(_ stream: Client.Connection) {
        available.append(stream)
        
        borrowed -= 1
        
        if waiting > 0 {
            try? waitList.send((), deadline: .immediately)
        }
    }
    
    fileprivate func dispose(_ stream: Client.Connection) {
        borrowed -= 1
    }
    
    fileprivate func borrow(deadline: Deadline) throws -> Client.Connection {
        var waitCount = 0
        
        while true {
            if let stream = available.popLast() {
                borrowed += 1
                return stream
            }
            
            if borrowed + available.count < size.upperBound {
                let stream = try create()
                borrowed += 1
                return stream
            }
            
            waitCount += 1
            
            defer {
                waiting -= waitCount
            }
            
            try waitList.receive(deadline: deadline)
        }
    }
}
