import struct Foundation.UUID
import struct Foundation.URL
import struct Foundation.URLComponents

public enum ParameterError : Error {
    case parameterNotFound(parameterKey: ParameterKey)
    case cannotExpress(type: ExpressibleByParameterString.Type, from: String)
}

public enum ParametersError : Error {
    case cannotInitialize(type: ParametersInitializable.Type, from: Parameters)
}

public struct ParameterKey {
    public let key: String
    
    public init(_ key: String) {
        self.key = key
    }
}

extension ParameterKey : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
    
    public init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
}

public protocol ExpressibleByParameterString {
    init(parameter: String) throws
}

extension String : ExpressibleByParameterString {
    public init(parameter: String) throws {
        self = parameter
    }
}

extension Int : ExpressibleByParameterString {
    public init(parameter: String) throws {
        guard let int = Int(parameter) else {
            throw ParameterError.cannotExpress(type: type(of: self), from: parameter)
        }
        
        self.init(int)
    }
}

extension UUID : ExpressibleByParameterString {
    public init(parameter: String) throws {
        guard let uuid = UUID(uuidString: parameter) else {
            throw ParameterError.cannotExpress(type: type(of: self), from: parameter)
        }
        
        self.init(uuid: uuid.uuid)
    }
}

extension Double : ExpressibleByParameterString {
    public init(parameter: String) throws {
        guard let double = Double(parameter) else {
            throw ParameterError.cannotExpress(type: type(of: self), from: parameter)
        }
        
        self.init(double)
    }
}

extension Float : ExpressibleByParameterString {
    public init(parameter: String) throws {
        guard let float = Float(parameter) else {
            throw ParameterError.cannotExpress(type: type(of: self), from: parameter)
        }
        
        self.init(float)
    }
}

extension Bool : ExpressibleByParameterString {
    public init(parameter: String) throws {
        switch parameter.lowercased() {
        case "true", "1", "t":
            self = true
        case "false", "0", "f":
            self = false
        default:
            throw ParameterError.cannotExpress(type: type(of: self), from: parameter)
        }
    }
}

public protocol ParametersInitializable {
    init(parameters: Parameters) throws
}

public struct NoParameters {
    public init() {}
}

extension NoParameters : ParametersInitializable {
    public init(parameters: Parameters) throws {}
}

public final class Parameters {
    var parameters: [String: String]
    
    public init(parameters: [String: String] = [:]) {
        self.parameters = parameters
    }
    
    public func set(_ parameter: String, for parameterKey: String) {
        parameters[parameterKey] = parameter
    }
    
    public func get<P : ExpressibleByParameterString>(_ parameterKey: ParameterKey) throws -> P {
        guard let parameter = parameters[parameterKey.key] else {
            throw ParameterError.parameterNotFound(parameterKey: parameterKey)
        }
        
        return try P(parameter: parameter)
    }
}
