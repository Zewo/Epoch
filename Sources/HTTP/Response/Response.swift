import Core
import Venice

public protocol ResponseRepresentable {
    var response: Response { get }
}

extension Content : ResponseRepresentable {
    public var response: Response {
        return Response(status: .ok, content: self)
    }
}

extension NoContent : ResponseRepresentable {
    public var response: Response {
        return Response(status: .noContent)
    }
}

extension ParameterError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case .parameterNotFound:
            return Response(status: .internalServerError)
        case .cannotExpress:
            // For example user tried to use string for int path parameters
            return Response(status: .badRequest)
        }
    }
}

extension ParametersError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case .cannotInitialize:
            return Response(status: .internalServerError)
        }
    }
}

public final class Response : Message {
    public typealias UpgradeConnection = (Request, DuplexStream) throws -> Void
    
    public var status: Status
    public var headers: Headers
    public var version: Version
    public var body: Body
    
    public var content: Content?
    public var storage: Storage = [:]
    
    public var upgradeConnection: UpgradeConnection?
    
    public var cookieHeaders: Set<String> = []
    
    public init(
        status: Status,
        headers: Headers,
        version: Version,
        body: Body
    ) {
        self.status = status
        self.headers = headers
        self.version = version
        self.body = body
    }
}

extension Response {
    public convenience init(
        status: Status,
        headers: Headers = [:]
    ) {
        self.init(
            status: status,
            headers: headers,
            version: .oneDotOne,
            body: .empty
        )
        
        contentLength = 0
    }
    
    public convenience init(
        status: Status,
        headers: Headers = [:],
        body stream: ReadableStream
    ) {
        self.init(
            status: status,
            headers: headers,
            version: .oneDotOne,
            body: .readable(stream)
        )
    }
    
    public convenience init(
        status: Status,
        headers: Headers = [:],
        body write: @escaping Body.Write
    ) {
        self.init(
            status: status,
            headers: headers,
            version: .oneDotOne,
            body: .writable(write)
        )
    }
    
    public convenience init(
        status: Status,
        headers: Headers = [:],
        content representable: ContentRepresentable
    ) {
        self.init(
            status: status,
            headers: headers
        )
        
        self.content = representable.content
    }
}

extension Response {
    public var cookies: Set<AttributedCookie> {
        get {
            var cookies = Set<AttributedCookie>()

            for header in cookieHeaders {
                if let cookie = AttributedCookie(header) {
                    cookies.insert(cookie)
                }
            }
            
            return cookies
        }
        
        set(cookies) {
            var cookieHeaders = Set<String>()
            
            for cookie in cookies {
                cookieHeaders.insert(cookie.description)
            }
            
            self.cookieHeaders = cookieHeaders
        }
    }
}

extension Response : ResponseRepresentable {
    public var response: Response {
        return self
    }
}

extension Response : CustomStringConvertible {
    public var statusLineDescription: String {
        return
            "HTTP/" + version.description + " " +
            status.description + "\n"
    }
    
    public var description: String {
        return
            statusLineDescription +
            headers.description + "\n" +
            (content?.description ?? "")
    }
}
