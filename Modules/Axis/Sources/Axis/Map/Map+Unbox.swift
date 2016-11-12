// MARK: map.<type>?

extension Map {
    public var bool: Bool? {
        guard case .bool(let bool) = self else {
            return nil
        }
        return bool
    }

    public var double: Double? {
        guard case .double(let double) = self else {
            return nil
        }
        return double
    }

    public var int: Int? {
        guard case .int(let int) = self else {
            return nil
        }
        return int
    }

    public var string: String? {
        guard case .string(let string) = self else {
            return nil
        }
        return string
    }

    public var buffer: Buffer? {
        guard case .buffer(let buffer) = self else {
            return nil
        }
        return buffer
    }

    public var array: [Map]? {
        guard case .array(let array) = self else {
            return nil
        }
        return array
    }

    public var dictionary: [String: Map]? {
        guard case .dictionary(let dictionary) = self else {
            return nil
        }
        return dictionary
    }
}

// MARK: is<Type>
extension Map {
    public var isBool: Bool {
        return bool != nil
    }

    public var isDouble: Bool {
        return double != nil
    }

    public var isInt: Bool {
        return int != nil
    }

    public var isString: Bool {
        return string != nil
    }

    public var isBuffer: Bool {
        return buffer != nil
    }

    public var isArray: Bool {
        return array != nil
    }

    public var isDictionary: Bool {
        return dictionary != nil
    }

    public var isNull: Bool {
        return self == .null
    }
}


// MARK: try map.as<Type>(converting:)

extension Map {
    public func asBool(converting: Bool = false) throws -> Bool {
        guard converting else {
            if let bool = bool {
                return bool
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .bool(let value):
            return value

        case .int(let value):
            return value != 0

        case .double(let value):
            return value != 0

        case .string(let value):
            switch value.lowercased() {
            case "true": return true
            case "false": return false
            default: throw MapError.incompatibleType
            }

        case .buffer(let value):
            return !value.isEmpty

        case .array(let value):
            return !value.isEmpty

        case .dictionary(let value):
            return !value.isEmpty

        case .null:
            return false
        }
    }

    public func asInt(converting: Bool = false) throws -> Int {
        guard converting else {
            if let int = int {
                return int
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .bool(let value):
            return value ? 1 : 0

        case .int(let value):
            return value

        case .double(let value):
            return Int(value)

        case .string(let value):
            if let int = Int(value) {
                return int
            }
            throw MapError.incompatibleType

        case .null:
            return 0

        default:
            throw MapError.incompatibleType
        }
    }

    public func asDouble(converting: Bool = false) throws -> Double {
        guard converting else {
            if let double = double {
                return double
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .bool(let value):
            return value ? 1.0 : 0.0

        case .int(let value):
            return Double(value)

        case .double(let value):
            return value

        case .string(let value):
            if let double = Double(value) {
                return double
            }
            throw MapError.incompatibleType

        case .null:
            return 0

        default:
            throw MapError.incompatibleType
        }
    }

    public func asString(converting: Bool = false) throws -> String {
        guard converting else {
            if let string = string {
                return string
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .bool(let value):
            return String(value)

        case .int(let value):
            return String(value)

        case .double(let value):
            return String(value)

        case .string(let value):
            return value

        case .buffer(let value):
            return try String(buffer: value)

        case .array:
            throw MapError.incompatibleType

        case .dictionary:
            throw MapError.incompatibleType

        case .null:
            return "null"
        }
    }

    public func asBuffer(converting: Bool = false) throws -> Buffer {
        guard converting else {
            if let buffer = buffer {
                return buffer
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .bool(let value):
            return value ? Buffer([0xff]) : Buffer([0x00])

        case .string(let value):
            return Buffer(value)

        case .buffer(let value):
            return value

        case .null:
            return Buffer()

        default:
            throw MapError.incompatibleType
        }
    }

    public func asArray(converting: Bool = false) throws -> [Map] {
        guard converting else {
            if let array = array {
                return array
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .array(let value):
            return value

        case .null:
            return []

        default:
            throw MapError.incompatibleType
        }
    }

    public func asDictionary(converting: Bool = false) throws -> [String: Map] {
        guard converting else {
            if let dictionary = dictionary {
                return dictionary
            }
            throw MapError.incompatibleType
        }

        switch self {
        case .dictionary(let value):
            return value

        case .null:
            return [:]

        default:
            throw MapError.incompatibleType
        }
    }
}

// MARK: Inferred
extension Map {
    public func asInferred<T : MapInitializable>(converting: Bool = false) throws -> T {
        switch T.self {
        case is Bool.Type: return try asBool(converting: converting) as! T
        case is Int.Type: return try asInt(converting: converting) as! T
        case is Double.Type: return try asDouble(converting: converting) as! T
        case is String.Type: return try asString(converting: converting) as! T
        case is Buffer.Type: return try asBuffer(converting: converting) as! T
        case is Array<Map>.Type: return try asArray(converting: converting) as! T
        case is Dictionary<String, Map>.Type: return try asDictionary(converting: converting) as! T
        default: return try T.init(map: self)
        }
    }
}
