import Core
import Foundation

public struct HeaderField {
    public let string: String
    
    public init(_ string: String) {
        self.string = string
    }
}

extension UTF8.CodeUnit {
    fileprivate func lowercased() -> UTF8.CodeUnit {
        let isUppercase = self >= 65 && self <= 90
        
        if isUppercase {
            return self + 32
        }
        
        return self
    }
}

extension String {
    fileprivate func caseInsensitiveCompare(_ other: String) -> Bool {
        if self.utf8.count != other.utf8.count {
            return false
        }
        
        for (lhs, rhs) in zip(self.utf8, other.utf8) {
            if lhs.lowercased() != rhs.lowercased() {
                return false
            }
        }
        
        return true
    }
}

extension HeaderField : Hashable {
    public var hashValue: Int {
        return string.hashValue
    }
    
    public static func == (lhs: HeaderField, rhs: HeaderField) -> Bool {
        if lhs.string == rhs.string {
            return true
        }
        
        return lhs.string.caseInsensitiveCompare(rhs.string)
    }
}

extension HeaderField : ExpressibleByStringLiteral {
    public init(stringLiteral string: String) {
        self.init(string)
    }
    
    public init(extendedGraphemeClusterLiteral string: String){
        self.init(string)
    }
    
    public init(unicodeScalarLiteral string: String){
        self.init(string)
    }
}

extension HeaderField : CustomStringConvertible {
    public var description: String {
        return string
    }
}

public struct Headers {
    public var headers: [HeaderField: String]
    
    public init(_ headers: [HeaderField: String]) {
        self.headers = headers
    }
}

extension Headers {
    public static var empty: Headers {
        return Headers()
    }
}

extension Headers : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (HeaderField, String)...) {
        var headers: [HeaderField: String] = [:]
        
        for (key, value) in elements {
            headers[key] = value
        }
        
        self.headers = headers
    }
}

extension Headers : Sequence {
    public func makeIterator() -> DictionaryIterator<HeaderField, String> {
        return headers.makeIterator()
    }
    
    public var count: Int {
        return headers.count
    }
    
    public var isEmpty: Bool {
        return headers.isEmpty
    }
    
    public subscript(field: HeaderField) -> String? {
        get {
            return headers[field]
        }
        
        set(header) {
            headers[field] = header
        }
    }
    
    public subscript(field: String) -> String? {
        get {
            return self[HeaderField(field)]
        }
        
        set(header) {
            self[HeaderField(field)] = header
        }
    }
}

extension Headers : CustomStringConvertible {
    public var description: String {
        var string = ""
        
        for (header, value) in headers {
            string += "\(header): \(value)\n"
        }
        
        return string
    }
}

extension Headers : Equatable {}

public func == (lhs: Headers, rhs: Headers) -> Bool {
    return lhs.headers == rhs.headers
}
