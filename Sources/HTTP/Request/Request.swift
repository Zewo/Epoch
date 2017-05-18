import Core
import Venice

import struct Foundation.URL

public final class Request : Message {
    public typealias UpgradeConnection = (Response, DuplexStream) throws -> Void
    
    public var method: Method
    public var uri: URI
    public var version: Version
    public var headers: Headers
    public var body: Body
    
    public var storage: Storage = [:]
    
    public var upgradeConnection: UpgradeConnection?
    
    public init(
        method: Method,
        uri: URI,
        headers: Headers = [:],
        version: Version = .oneDotOne,
        body: Body
    ) {
        self.method = method
        self.uri = uri
        self.headers = headers
        self.version = version
        self.body = body
    }
    
    public enum Method {
        case delete
        case get
        case head
        case post
        case put
        case connect
        case options
        case trace
        case patch
        case other(String)
    }
}

extension Request {
    public convenience init(
        method: Method,
        url: URL,
        headers: Headers = [:]
    ) {
        self.init(
            method: method,
            uri: URI(url: url),
            headers: headers,
            version: .oneDotOne,
            body: .empty
        )
        
        contentLength = 0
    }
    
    public convenience init(
        method: Method,
        url: URL,
        headers: Headers = [:],
        body stream: ReadableStream
    ) {
        self.init(
            method: method,
            uri: URI(url: url),
            headers: headers,
            version: .oneDotOne,
            body: .readable(stream)
        )
    }
    
    public convenience init(
        method: Method,
        url: URL,
        headers: Headers = [:],
        body write: @escaping Body.Write
    ) {
        self.init(
            method: method,
            uri: URI(url: url),
            headers: headers,
            version: .oneDotOne,
            body: .writable(write)
        )
    }
    
    public convenience init(
        method: Method,
        url: URL,
        headers: Headers = [:],
        body buffer: BufferRepresentable,
        timeout: Duration
    ) {
        self.init(
            method: method,
            uri: URI(url: url),
            headers: headers,
            version: .oneDotOne,
            body: .writable { stream in
                try stream.write(buffer, deadline: timeout.fromNow())
            }
        )
        
        contentLength = buffer.bufferSize
    }
    
    public convenience init(
        method: Method,
        url: URL,
        headers: Headers = [:],
        content: Content,
        contentType: ContentType,
        bufferSize: Int = 2048,
        timeout: Duration = 5.minutes
    ) {
        self.init(
            method: method,
            uri: URI(url: url),
            headers: headers,
            version: .oneDotOne,
            body: .writable { stream in
                try contentType.serializer.serialize(
                    content,
                    stream: stream,
                    bufferSize: bufferSize,
                    deadline: timeout.fromNow()
                )
            }
        )
        
        self.contentType = contentType.mediaType
        self.contentLength = nil
        self.transferEncoding = "chunked"
    }
    
    public convenience init(
        method: Method,
        url: URL,
        headers: Headers = [:],
        content: ContentRepresentable,
        contentType: ContentType,
        bufferSize: Int = 2048,
        timeout: Duration = 5.minutes
    ) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            content: content.content,
            contentType: contentType,
            timeout: timeout
        )
    }
}

extension Request {
    public var accept: [MediaType] {
        get {
            return headers["Accept"].map({ MediaType.parse(acceptHeader: $0) }) ?? []
        }
        
        set(accept) {
            headers["Accept"] = accept.map({ $0.type + "/" + $0.subtype }).joined(separator: ", ")
        }
    }
    
    public var cookies: Set<Cookie> {
        get {
            return headers["Cookie"].map({ Cookie.parse(cookieHeader: $0) }) ?? []
        }
    }
    
    public var authorization: String? {
        get {
            return headers["Authorization"]
        }
    }
    
    public var host: String? {
        get {
            return headers["Host"]
        }
    }
    
    public var userAgent: String? {
        get {
            return headers["User-Agent"]
        }
    }
}

extension Request : CustomStringConvertible {
    /// :nodoc:
    public var requestLineDescription: String {
        return method.description + " " + uri.description + " " + version.description + "\n"
    }
    
    /// :nodoc:
    public var description: String {
        return requestLineDescription + headers.description
    }
}

// TODO: Make error CustomStringConvertible and ResponseRepresentable
public enum RequestContentError : Error {
    case noReadableBody
    case noContentTypeHeader
    case unsupportedMediaType
}

extension Request {
    public func getParameters<P : ParametersInitializable>() throws -> P {
        return try P(parameters: uri.parameters)
    }
    
    public func getContent(
        _ contentType: ContentType,
        deadline: Deadline = 5.minutes.fromNow()
    ) throws -> Content {
        guard let mediaType = self.contentType else {
            throw RequestContentError.noContentTypeHeader
        }
        
        guard mediaType == contentType.mediaType else {
            throw RequestContentError.unsupportedMediaType
        }
        
        guard let stream = body.readable else {
            throw RequestContentError.noReadableBody
        }
        
        return try contentType.parser.parse(stream, deadline: deadline)
    }
    
    public func getContent<C : ContentInitializable>(
        _ contentType: ContentType,
        deadline: Deadline = 5.minutes.fromNow()
    ) throws -> C {
        let content = try getContent(contentType, deadline: deadline)
        return try C(content: content)
    }
}
