import struct Foundation.URLComponents

public enum URIError : Error {
    case invalidURI
}

/**
 The generic URI [syntax](https://tools.ietf.org/html/rfc3986#section-1) consists of a hierarchical sequence of
 components referred to as the `scheme`, `userInfo`, `host`, `port`, `path`, `query`, and
 `fragment`.

 The following example URI and their component parts:
 
 ```
 foo://username:password@example.com:8042/over/there?name=ferret#nose
 \_/   \_______________/ \_________/ \__/ \________/ \_________/ \__/
 |           |                |       |       |           |       |
 scheme  user info           host    port    path       query  fragment
 ```
 */
public struct URI {
    public var scheme: String?
    public var userInfo: UserInfo?
    public var host: String?
    public var port: Int?
    public var path: String?
    public var query:  String?
    public var fragment: String?
    
    fileprivate var params: Parameters
    
    internal init(
        scheme: String? = nil,
        userInfo: UserInfo? = nil,
        host: String? = nil,
        port: Int? = nil,
        path: String? = nil,
        query: String? = nil,
        fragment: String? = nil
    ) {
        self.scheme = scheme
        self.userInfo = userInfo
        self.host = host
        self.port = port
        self.path = path
        self.query = query
        self.fragment = fragment
        
        if let query = query?.removingPercentEncoding {
            self.params = Parameters(query: query)
        } else {
            self.params = Parameters()
        }
    }
    
    public struct Parameters {
        var parameters: [String: String]

        init(_ parameters: [String: String] = [:]) {
            self.parameters = parameters
        }
        
        init(query: String) {
            var parameters: [String: String] = [:]
            let components = query.components(separatedBy: "&")
            
            for component in components {
                let pair = component.components(separatedBy: "=")
                
                if pair.count == 2 {
                    parameters[pair[0]] = pair[1]
                }
            }
            
            self.init(parameters)
        }
    }
    
    public struct UserInfo {
        public var username: String
        public var password: String?
        
        internal init(username: String, password: String?) {
            self.username = username
            self.password = password
        }
    }
}

extension URI {
    public mutating func set(parameter: String, key: String) {
        params.parameters[key] = parameter
    }
    
    public func parameters<P : ParametersInitializable>() throws -> P {
        return try P(parameters: params)
    }
    
    public func parameter(_ key: String) throws -> String {
        return try params.get(key)
    }
    
    public func parameter<P : LosslessStringConvertible>(_ key: String) throws -> P {
        return try params.get(key)
    }
}

extension URI : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        var string = ""
        
        if let scheme = scheme {
            string += scheme
            string += "://"
        }
        
        if let userInfo = userInfo {
            string += userInfo.description
            string += "@"
        }
        
        if let host = host {
            string += host
        }
        
        if let port = port {
            string += ":"
            string += port.stringValue
        }
        
        if let path = path {
            string += path
        }
        
        if let query = query {
            string += "?"
            string += query
        }
        
        if let fragment = fragment {
            string += "#"
            string += fragment
        }
        
        return string
    }
}

extension URI {
    /// Creates an `URI` from a string.
    public init(_ string: String) throws {
        guard let url = URLComponents(string: string) else {
            throw URIError.invalidURI
        }
        
        self.scheme = url.scheme
        
        self.userInfo = url.percentEncodedUser.map {
            UserInfo(username: $0, password: url.percentEncodedPassword)
        }
        
        self.host = url.percentEncodedHost
        self.port = url.port
        self.path = url.percentEncodedPath
        self.query = url.percentEncodedQuery
        self.fragment = url.percentEncodedFragment
        
        if let query = url.query {
            self.params = Parameters(query: query)
        } else {
            self.params = Parameters()
        }
    }
}

extension URI.UserInfo : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        guard let password = password else {
            return username
        }

        return username + ":" + password
    }
}

extension URI.Parameters : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        var string = "{"
        
        for (offset: index, element: (key: key, value: value)) in parameters.enumerated() {
            string += key + ": " + value
            
            if index < parameters.count - 1 {
                string += ", "
            }
        }
        
        return string + "}"
    }
}
