import Foundation

public enum ContentError : Error {
    case cannotInitialize(type: ContentInitializable.Type, from: Content)
    case cannotGet(type: Any.Type, from: Content)
    case outOfBounds(index: Int, count: Int)
    case valueNotFound(key: String)
}

public protocol ContentInitializable {
    init(content: Content) throws
}

public protocol ContentRepresentable {
    var content: Content { get }
}

public protocol ContentConvertible : ContentInitializable, ContentRepresentable {}

extension Int : ContentConvertible {
    public var content: Content {
        return .int(self)
    }

    public init(content: Content) throws {
        guard case .int(let value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), from: content)
        }

        self = value
    }
}

extension Bool : ContentConvertible {
    public var content: Content {
        return .bool(self)
    }

    public init(content: Content) throws {
        guard case .bool(let value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), from: content)
        }

        self = value
    }
}

extension String : ContentConvertible {
    public var content: Content {
        return .string(self)
    }

    public init(content: Content) throws {
        guard case .string(let value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), from: content)
        }

        self = value
    }
}

extension Double : ContentConvertible {
    public var content: Content {
        return .double(self)
    }

    public init(content: Content) throws {
        guard case .double(let value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), from: content)
        }

        self = value
    }
}

extension Content : ContentConvertible {
    public var content: Content {
        return self
    }

    public init(content: Content) throws {
        self = content
    }
}

public struct NoContent {
    public init() {}
}

extension NoContent : ContentConvertible {
    public init(content: Content) throws {}
    
    public var content: Content {
        return .array([])
    }
}

public enum Content {
    case null
    case bool(Bool)
    case double(Double)
    case int(Int)
    case string(String)
    case data(Data)
    case array([Content])
    case dictionary([String: Content])
}

extension Content {
    public init<T: ContentRepresentable>(_ value: T?) {
        self = value?.content ?? .null
    }
    
    public init<T: ContentRepresentable>(_ values: [T]?) {
        if let values = values {
            self = .array(values.map({$0.content}))
        } else {
            self = .null
        }
    }
    
    public init<T: ContentRepresentable>(_ values: [T?]?) {
        if let values = values {
            self = .array(values.map({$0?.content ?? .null}))
        } else {
            self = .null
        }
    }
    
    public init<T: ContentRepresentable>(_ values: [String: T]?) {
        if let values = values {
            var dictionary: [String: Content] = [:]
            
            for (key, value) in values.map({($0.key, $0.value.content)}) {
                dictionary[key] = value
            }
            
            self = .dictionary(dictionary)
        } else {
            self = .null
        }
    }
    
    public init<T: ContentRepresentable>(_ values: [String: T?]?) {
        if let values = values {
            var dictionary: [String: Content] = [:]
            
            for (key, value) in values.map({($0.key, $0.value?.content ?? .null)}) {
                dictionary[key] = value
            }
            
            self = .dictionary(dictionary)
        } else {
            self = .null
        }
    }
}

public enum IndexPathComponentValue {
    case index(Int)
    case key(String)
}

/// Can be represented as `IndexPathValue`.
public protocol IndexPathComponent {
    var indexPathComponent: IndexPathComponentValue { get }
}

extension Int : IndexPathComponent {
    public var indexPathComponent: IndexPathComponentValue {
        return .index(self)
    }
}

extension String : IndexPathComponent {
    public var indexPathComponent: IndexPathComponentValue {
        return .key(self)
    }
}

extension Content {
    public func get<T : ContentInitializable>(_ indexPath: IndexPathComponent...) throws -> T {
        let content = try get(indexPath)
        return try T(content: content)
    }
    
    public func get(_ indexPath: IndexPathComponent...) throws -> Content {
        return try get(indexPath)
    }
    
    private func get(_ indexPath: [IndexPathComponent]) throws -> Content {
        var value: Content = self
        
        for element in indexPath {
            switch element.indexPathComponent {
            case let .index(index):
                let array: [Content] = try get()
                
                if array.indices.contains(index) {
                    value = array[index]
                } else {
                    throw ContentError.outOfBounds(index: index, count: array.count)
                }
                
            case let .key(key):
                let dictionary: [String: Content] = try get()
                
                if let newValue = dictionary[key] {
                    value = newValue
                } else {
                    throw ContentError.valueNotFound(key: key)
                }
            }
        }
        
        return value
    }
    
    private func get<T>(_ indexPath: IndexPathComponent...) throws -> T {
        if indexPath.isEmpty {
            switch self {
            case let .bool(value as T):
                return value
            case let .int(value as T):
                return value
            case let .double(value as T):
                return value
            case let .string(value as T):
                return value
            case let .data(value as T):
                return value
            case let .array(value as T):
                return value
            case let .dictionary(value as T):
                return value
            default:
                throw ContentError.cannotGet(type: T.self, from: self)
            }
        }
        
        return try get(indexPath).get()
    }
}

extension Content : Equatable {}

public func == (lhs: Content, rhs: Content) -> Bool {
    switch (lhs, rhs) {
    case (.null, .null): return true
    case let (.int(l), .int(r)) where l == r: return true
    case let (.bool(l), .bool(r)) where l == r: return true
    case let (.string(l), .string(r)) where l == r: return true
    case let (.data(l), .data(r)) where l == r: return true
    case let (.double(l), .double(r)) where l == r: return true
    case let (.array(l), .array(r)) where l == r: return true
    case let (.dictionary(l), .dictionary(r)) where l == r: return true
    default: return false
    }
}

extension Content : ExpressibleByNilLiteral {
    public init(nilLiteral value: Void) {
        self = .null
    }
}

extension Content : ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: BooleanLiteralType) {
        self = .bool(value)
    }
}

extension Content : ExpressibleByIntegerLiteral {
    public init(integerLiteral value: IntegerLiteralType) {
        self = .int(value)
    }
}

extension Content : ExpressibleByFloatLiteral {
    public init(floatLiteral value: FloatLiteralType) {
        self = .double(value)
    }
}

extension Content : ExpressibleByStringLiteral {
    public init(unicodeScalarLiteral value: String) {
        self = .string(value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self = .string(value)
    }
    
    public init(stringLiteral value: StringLiteralType) {
        self = .string(value)
    }
}

extension Content : ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Content...) {
        self = .array(elements)
    }
}

extension Content : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Content)...) {
        var dictionary = [String: Content](minimumCapacity: elements.count)
        
        for (key, value) in elements {
            dictionary[key] = value
        }
        
        self = .dictionary(dictionary)
    }
}

extension Content : CustomStringConvertible {
    public var description: String {
        let escapeMapping: [UnicodeScalar: String.UnicodeScalarView] = [
            "\r": "\\r".unicodeScalars,
            "\n": "\\n".unicodeScalars,
            "\t": "\\t".unicodeScalars,
            "\\": "\\\\".unicodeScalars,
            "\"": "\\\"".unicodeScalars,
            
            "\u{2028}": "\\u2028".unicodeScalars,
            "\u{2029}": "\\u2029".unicodeScalars,
        ]
        
        func escape(_ source: String) -> String {
            var string: String.UnicodeScalarView = "\"".unicodeScalars
            
            for scalar in source.unicodeScalars {
                if let escaped = escapeMapping[scalar] {
                    string.append(contentsOf: escaped)
                } else {
                    string.append(scalar)
                }
            }
            
            string.append("\"")
            
            return String(string)
        }
        
        func serialize(content: Content) -> String {
            switch content {
            case .null: return "null"
            case .bool(let bool): return String(bool)
            case .double(let number): return String(number)
            case .int(let number): return String(number)
            case .string(let string): return escape(string)
            case .data(let data): return "b64:" + data.base64EncodedString()
            case .array(let array): return serialize(array: array)
            case .dictionary(let dictionary): return serialize(dictionary: dictionary)
            }
        }
        
        func serialize(array: [Content]) -> String {
            var string = "["
            
            for index in 0 ..< array.count {
                string += serialize(content: array[index])
                
                if index != array.count - 1 {
                    string += ","
                }
            }
            
            return string + "]"
        }
        
        func serialize(dictionary: [String: Content]) -> String {
            var string = "{"
            var index = 0
            
            for (key, value) in dictionary.sorted(by: {$0.0 < $1.0}) {
                string += escape(key) + ":" + serialize(content: value)
                
                if index != dictionary.count - 1 {
                    string += ","
                }
                
                index += 1
            }
            
            return string + "}"
        }
        
        return serialize(content: self)
    }
}
