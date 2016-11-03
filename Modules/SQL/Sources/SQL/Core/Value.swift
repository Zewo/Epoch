import Axis
import Foundation

public enum Value {
    case string(String)
    case buffer(Buffer)
}

public struct ValueError: Error {
	let description: String
}

public protocol ValueConvertible: ParameterConvertible {
    var sqlValue: Value { get }

    init(rawSQLData: Buffer) throws
}

extension ValueConvertible {
    public var sqlParameter: Parameter {
        return .value(self.sqlValue)
    }
}

extension Buffer: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        self = buffer
    }

    public var sqlValue: Value {
        return .buffer(self)
    }
}

extension String: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        try self.init(buffer: buffer)
    }

    public var sqlValue: Value {
        return .string(self)
    }
}

extension Data : ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        self.init(buffer.bytes)
    }

    public var sqlValue: Value {
        return .buffer(Buffer(Array(self)))
    }
}

extension Float: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Float(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Float")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension Double: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Double(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Double")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension Int : ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Int(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Int")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension Int8 : ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Int8(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Int")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension Int16 : ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Int16(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Int")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension Int32 : ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Int32(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Int")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension Int64 : ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = Int64(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to Int")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension UInt: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = UInt(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to UInt")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension UInt8: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = UInt8(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to UInt")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension UInt16: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = UInt16(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to UInt")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension UInt32: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = UInt32(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to UInt")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}

extension UInt64: ValueConvertible {
    public init(rawSQLData buffer: Buffer) throws {
        guard let value = UInt64(try String(buffer: buffer)) else {
            throw ValueError(description: "Failed to convert data to UInt")
        }
        self = value
    }

    public var sqlValue: Value {
        return .string(String(self))
    }
}
