import CHTTPParser

/**
 https://tools.ietf.org/html/rfc3986#section-1
 
 3.  Syntax Components
 
 The generic URI syntax consists of a hierarchical sequence of
 components referred to as the scheme, authority, path, query, and
 fragment.
 
 URI         = scheme ":" hier-part [ "?" query ] [ "#" fragment ]
 
 hier-part   = "//" authority path-abempty
 / path-absolute
 / path-rootless
 / path-empty
 
 The scheme and path components are required, though the path may be
 empty (no characters).  When authority is present, the path must
 either be empty or begin with a slash ("/") character.  When
 authority is not present, the path cannot begin with two slash
 characters ("//").  These restrictions result in five different ABNF
 rules for a path (Section 3.3), only one of which will match any
 given URI reference.
 
 The following are two example URIs and their component parts:
 
 foo://example.com:8042/over/there?name=ferret#nose
 \_/   \______________/\_________/ \_________/ \__/
 |           |            |            |        |
 scheme     authority       path        query   fragment
 |   _____________________|__
 / \ /                        \
 urn:example:animal:ferret:nose
 */
public struct URI {
    public struct UserInfo {
        public var username: String
        public var password: String
        
        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }
    }
    
    public var scheme: String?
    public var userInfo: UserInfo?
    public var host: String?
    public var port: Int?
    public var path: String?
    public var query:  String?
    public var fragment: String?
    
    public init(scheme: String? = nil,
                userInfo: UserInfo? = nil,
                host: String? = nil,
                port: Int? = nil,
                path: String? = nil,
                query: String? = nil,
                fragment: String? = nil) {
        self.scheme = scheme
        self.userInfo = userInfo
        self.host = host
        self.port = port
        self.path = path
        self.query = query
        self.fragment = fragment
    }
    
    public init?(buffer: UnsafeRawBufferPointer, isConnect: Bool) {
        let uri = parse_uri(
            buffer.baseAddress?.assumingMemoryBound(to: Int8.self),
            buffer.count,
            isConnect ? 1 : 0
        )
        
        if uri.error == 1 {
            return nil
        }
        
        if uri.field_set & 1 != 0 {
            scheme = URI.substring(buffer: buffer, start: uri.scheme_start, end: uri.scheme_end)
        } else {
            scheme = nil
        }

        if uri.field_set & 2 != 0 {
            host = URI.substring(buffer: buffer, start: uri.host_start, end: uri.host_end)
        } else {
            host = nil
        }
        
        if uri.field_set & 4 != 0 {
            port = Int(uri.port)
        } else {
            port = nil
        }
        
        if uri.field_set & 8 != 0 {
            path = URI.substring(buffer: buffer, start: uri.path_start, end: uri.path_end)
        } else {
            path = nil
        }
        
        if uri.field_set & 16 != 0 {
            query = URI.substring(buffer: buffer, start: uri.query_start, end: uri.query_end)
        } else {
            query = nil
        }
        
        if uri.field_set & 32 != 0 {
            fragment = URI.substring(buffer: buffer, start: uri.fragment_start, end: uri.fragment_end)
        } else {
            fragment = nil
        }
        
        if uri.field_set & 64 != 0 {
            let userInfoString = URI.substring(buffer: buffer, start: uri.user_info_start, end: uri.user_info_end)
            userInfo = URI.userInfo(userInfoString)
        } else {
            userInfo = nil
        }
    }
    
    @inline(__always)
    private static func substring(buffer: UnsafeRawBufferPointer, start: UInt16, end: UInt16) -> String {
        let bytes = [UInt8](buffer[Int(start) ..< Int(end)]) + [0]

        return bytes.withUnsafeBufferPointer { (pointer: UnsafeBufferPointer<UInt8>) -> String in
            return String(cString: pointer.baseAddress!)
        }
    }
    
    @inline(__always)
    private static func userInfo(_ string: String?) -> URI.UserInfo? {
        guard let string = string else {
            return nil
        }
        
        let components = string.components(separatedBy: ":")
        
        if components.count == 2 {
            return URI.UserInfo(
                username: components[0],
                password: components[1]
            )
        }
        
        return nil
    }
}

extension URI : CustomStringConvertible {
    public var description: String {
        var string = ""
        
        if let scheme = scheme {
            string += "\(scheme)://"
        }
        
        if let userInfo = userInfo {
            string += "\(userInfo)@"
        }
        
        if let host = host {
            string += "\(host)"
        }
        
        if let port = port {
            string += ":\(port)"
        }
        
        if let path = path {
            string += "\(path)"
        }
        
        if let query = query {
            string += "\(query)"
        }
        
        if let fragment = fragment {
            string += "#\(fragment)"
        }
        
        return string
    }
}
