public enum HTTPClientError : Error {
    case invalidURIScheme
    case uriHostRequired
    case brokenConnection
}

public final class Client : Responder {
    fileprivate let secure: Bool

    public let host: String
    public let port: Int

    public let keepAlive: Bool
    public let connectionTimeout: Double
    public let requestTimeout: Double
    public let bufferSize: Int

    public let certificatePath: String?
    public let privateKeyPath: String?
    public let verifyBundlePath: String?
    public let certificateChainPath: String?

    let addUserAgent: Bool

    var stream: Stream?
    var serializer: RequestSerializer?
    var parser: MessageParser?

    public init(url: URL, bufferSize: Int = 4096, connectionTimeout: Double = 3.minutes, requestTimeout: Double = 30.seconds, certificatePath: String? = nil, privateKeyPath: String? = nil, certificateChainPath: String? = nil, verifyBundlePath: String? = nil, keepAlive: Bool = true, addUserAgent: Bool = true) throws {
        self.secure = try isSecure(url: url)

        let (host, port) = try getHostPort(url: url)

        self.host = host
        self.port = port

        self.bufferSize = bufferSize
        self.connectionTimeout = connectionTimeout
        self.requestTimeout = requestTimeout

        self.certificatePath = certificatePath
        self.privateKeyPath = privateKeyPath
        self.certificateChainPath = certificateChainPath
        self.verifyBundlePath = verifyBundlePath

        self.addUserAgent = addUserAgent

        self.keepAlive = keepAlive
    }

    public convenience init(url: String, bufferSize: Int = 4096, connectionTimeout: Double = 3.minutes, requestTimeout: Double = 30.seconds, certificatePath: String? = nil, privateKeyPath: String? = nil, verifyBundlePath: String? = nil, keepAlive: Bool = true, addUserAgent: Bool = true) throws {
        guard let url = URL(string: url) else {
            throw URLError.invalidURL
        }

        try self.init(
            url: url,
            bufferSize: bufferSize,
            connectionTimeout: connectionTimeout,
            requestTimeout: requestTimeout,
            certificatePath: certificatePath,
            privateKeyPath: privateKeyPath,
            verifyBundlePath: verifyBundlePath,
            keepAlive: keepAlive,
            addUserAgent: addUserAgent
        )
    }
}

extension Client {
    public func request(_ request: Request, middleware: [Middleware] = []) throws -> Response {
        var request = request
        addHeaders(to: &request)
        return try middleware.chain(to: self).respond(to: request)
    }

    public func respond(to request: Request) throws -> Response {
        var request = request
        addHeaders(to: &request)

        let stream = try getStream()
        let serializer = getSerializer(stream: stream)
        let parser = getParser()

        self.stream = stream
        self.serializer = serializer
        self.parser = parser

        let requestDeadline = now() + requestTimeout

        do {
            // TODO: Add deadline to serializer
            // TODO: Deal with multiple responses

            try serializer.serialize(request, deadline: requestDeadline)
            
            var response: Response!
            while !stream.closed {
                let chunk = try stream.read(upTo: bufferSize, deadline: requestDeadline)
                for message in try parser.parse(chunk) {
                    response = message as! Response
                }
            }

            if let upgrade = request.upgradeConnection {
                try upgrade(response, stream)
            }

            if response.isError || !keepAlive {
                self.stream = nil
            }

            return response
        } catch let error as StreamError {
            self.stream = nil
            throw error
        }
    }

    private func addHeaders(to request: inout Request) {
        request.host = request.host ?? "\(host):\(port)"

        if addUserAgent {
            request.userAgent = request.userAgent ?? "Zewo"
        }

        if !keepAlive {
            request.connection = request.connection ?? "close"
        }
    }

    private func getStream() throws -> Stream {
        if let stream = self.stream {
            return stream
        }

        let stream: Stream

        if secure {
            stream = try TCPTLSStream(
                host: host,
                port: port,
                certificatePath: certificatePath,
                privateKeyPath: privateKeyPath,
                certificateChainPath: certificateChainPath,
                verifyBundle: verifyBundlePath,
                sniHostname: host,
                deadline: now() + connectionTimeout
            )
        } else {
            stream = try TCPStream(
                host: host,
                port: port,
                deadline: now() + connectionTimeout
            )
        }

        try stream.open(deadline: now() + connectionTimeout)
        return stream
    }

    private func getSerializer(stream: Stream) -> RequestSerializer {
        if let serializer = serializer {
            return serializer
        }
        return RequestSerializer(stream: stream)
    }


    private func getParser() -> MessageParser {
        if let parser = self.parser {
            return parser
        }
        return MessageParser(mode: .response)
    }
}

extension Client {
    public func get(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .get, url: url, headers: headers, body: body, middleware: middleware)
    }

    public func head(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .head, url: url, headers: headers, body: body, middleware: middleware)
    }

    public func post(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .post, url: url, headers: headers, body: body, middleware: middleware)
    }

    public func put(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .put, url: url, headers: headers, body: body, middleware: middleware)
    }

    public func patch(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .patch, url: url, headers: headers, body: body, middleware: middleware)
    }

    public func delete(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .delete, url: url, headers: headers, body: body, middleware: middleware)
    }

    public func options(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .options, url: url, headers: headers, body: body, middleware: middleware)
    }

    private func request(method: Request.Method, url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        guard let url = URL(string: url) else {
            throw URLError.invalidURL
        }
        let req = Request(method: method, url: url, headers: headers, body: body.buffer)
        return try request(req, middleware: middleware)
    }
}

extension Client {
    public static func get(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .get, url: url, headers: headers, body: body, middleware: middleware)
    }

    public static func head(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .head, url: url, headers: headers, body: body, middleware: middleware)
    }

    public static func post(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .post, url: url, headers: headers, body: body, middleware: middleware)
    }

    public static func put(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .put, url: url, headers: headers, body: body, middleware: middleware)
    }

    public static func patch(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .patch, url: url, headers: headers, body: body, middleware: middleware)
    }

    public static func delete(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .delete, url: url, headers: headers, body: body, middleware: middleware)
    }

    public static func options(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> Response {
        return try request(method: .options, url: url, headers: headers, body: body, middleware: middleware)
    }

    fileprivate static func request(method: Request.Method, url: String, headers: Headers = [:], body: BufferRepresentable, middleware: [Middleware] = []) throws -> Response {
        guard let clientUrl = URL(string: url) else {
            throw URLError.invalidURL
        }

        let client = try getCachedClient(url: clientUrl)

        let request = Request(method: method, url: clientUrl, headers: headers, body: body.buffer)
        return try client.request(request, middleware: middleware)
    }

    private static func getCachedClient(url: URL) throws -> Client {
        let (host, port) = try getHostPort(url: url)
        let hash = host.hashValue ^ port.hashValue

        guard let client = cachedClients[hash] else {
            let client = try Client(url: url)
            cachedClients[hash] = client
            return client
        }

        return client
    }
}

public class TypedResponse<T : MapInitializable> {
    public let response: Response
    public let content: T

    public init(response: Response) throws {
        guard let content = response.content else {
            throw MapError.incompatibleType
        }
        self.response = response
        self.content = try T(map: content)
    }
}

//extension Client {
//    public static func get<T : MapInitializable>(_ url: String, headers: Headers = [:], body: BufferRepresentable = Buffer(), middleware: [Middleware] = []) throws -> TypedResponse<T> {
//        let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [JSON.self], mode: .client)
//        var chain: [Middleware] = [contentNegotiation]
//        chain += middleware
//        let response = try request(method: .get, url: url, headers: headers, body: body, middleware: chain)
//        return try TypedResponse(response: response)
//    }
//}

fileprivate func isSecure(url: URL) throws -> Bool {
    let scheme = url.scheme ?? "http"

    switch scheme {
    case "http": return false
    case "https": return true
    default: throw HTTPClientError.invalidURIScheme
    }
}

fileprivate func getHostPort(url: URL) throws -> (String, Int) {
    let scheme = url.scheme ?? "http"

    guard let host = url.host else {
        throw HTTPClientError.uriHostRequired
    }

    let port: Int

    switch scheme {
    case "http": port = url.port ?? 80
    case "https": port = url.port ?? 443
    default: throw HTTPClientError.invalidURIScheme
    }

    return (host, port)
}

private var cachedClients: [Int: Client] = [:]
