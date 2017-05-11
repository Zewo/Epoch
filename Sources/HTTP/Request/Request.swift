import Core
import Foundation

public final class Request : Message {
    public typealias UpgradeConnection = (Response, DuplexStream) throws -> Void
    
    public var method: Method
    public var url: URI
    public var version: Version
    public var headers: Headers
    public var body: Body
    
    public var content: Content?
    public var storage: Storage = [:]
    
    public var upgradeConnection: UpgradeConnection?
    
    lazy var parameters: Parameters = Parameters(url: self.url)
    
    public init(
        method: Method,
        url: URI,
        headers: Headers = [:],
        version: Version = .oneDotOne,
        body: Body
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.version = version
        self.body = body
    }
}

extension Parameters {
    public convenience init(url: URI) {
        guard let query = url.query else {
            self.init()
            return
        }

        var parameters: [String: String] = [:]
        let components = query.components(separatedBy: "&")
        
        for component in components {
            let pair = component.components(separatedBy: "=")
            
            if pair.count == 2 {
                parameters[pair[0]] = pair[1]
            }
        }

        self.init(parameters: parameters)
    }
}

extension Request {
    public convenience init(
        method: Method,
        url: URI,
        headers: Headers = [:]
    ) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            version: .oneDotOne,
            body: .empty
        )
        
        contentLength = 0
    }
    
    public convenience init(
        method: Method,
        url: URI,
        headers: Headers = [:],
        body stream: ReadableStream
    ) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            version: .oneDotOne,
            body: .readable(stream)
        )
    }
}

extension Request {
    public var accept: [MediaType] {
        get {
            var acceptedMediaTypes: [MediaType] = []
            
            if let acceptString = headers["Accept"] {
                let acceptedTypesString = acceptString.components(separatedBy: ",")
                
                for acceptedTypeString in acceptedTypesString {
                    let acceptedTypeTokens = acceptedTypeString.components(separatedBy: ";")
                    
                    if acceptedTypeTokens.count >= 1 {
                        let mediaTypeString = acceptedTypeTokens[0].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let acceptedMediaType = try? MediaType(string: mediaTypeString) {
                            acceptedMediaTypes.append(acceptedMediaType)
                        }
                    }
                }
            }
            
            return acceptedMediaTypes
        }
        
        set(accept) {
            headers["Accept"] = accept.map({$0.type + "/" + $0.subtype}).joined(separator: ", ")
        }
    }
    
    public var cookies: Set<Cookie> {
        get {
            return headers["Cookie"].flatMap({Set<Cookie>(cookieHeader: $0)}) ?? []
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
    public var requestLineDescription: String {
        return method.description + " " + url.description + " " + version.description + "\n"
    }
    
    public var description: String {
        return requestLineDescription + headers.description
    }
}

extension Request {
    public func getParameters<P : ParametersInitializable>() throws -> P {
        if let noParams = NoParameters() as? P {
            return noParams
        }
        
        return try P(parameters: parameters)
    }
    
    public func getContent<C : ContentInitializable>() throws -> C {
        if let noContent = NoContent() as? C {
            return noContent
        }
        
        guard let content = content else {
            throw ContentError.cannotInitialize(type: C.self, from: .null)
        }
        
        return try C(content: content)
    }
}
