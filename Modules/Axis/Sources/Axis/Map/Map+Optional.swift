// MARK: Optional.<type>?

extension Optional where Wrapped : MapRepresentable {
    public var bool: Bool? {
        return map.bool
    }

    public var double: Double? {
        return map.double
    }

    public var int: Int? {
        return map.int
    }

    public var string: String? {
        return map.string
    }

    public var buffer: Buffer? {
        return map.buffer
    }

    public var array: [Map]? {
        return map.array
    }

    public var dictionary: [String: Map]? {
        return map.dictionary
    }
}

// MARK: Optional.is<Type>

extension Optional where Wrapped : MapRepresentable {
    public var isBool: Bool {
        return map.isBool
    }

    public var isDouble: Bool {
        return map.isDouble
    }

    public var isInt: Bool {
        return map.isInt
    }

    public var isString: Bool {
        return map.isString
    }

    public var isBuffer: Bool {
        return map.isBuffer
    }

    public var isArray: Bool {
        return map.isArray
    }

    public var isDictionary: Bool {
        return map.isDictionary
    }

    public var isNull: Bool {
        return map.isNull
    }
}

// MARK: try Optional.as<Type>(converting:)

extension Optional where Wrapped : MapRepresentable {
    public func asBool(converting: Bool = false) throws -> Bool {
        return try map.asBool(converting: converting)
    }

    public func asInt(converting: Bool = false) throws -> Int {
        return try map.asInt(converting: converting)
    }

    public func asDouble(converting: Bool = false) throws -> Double {
        return try map.asDouble(converting: converting)
    }

    public func asString(converting: Bool = false) throws -> String {
        return try map.asString(converting: converting)
    }

    public func asBuffer(converting: Bool = false) throws -> Buffer {
        return try map.asBuffer(converting: converting)
    }

    public func asArray(converting: Bool = false) throws -> [Map] {
        return try map.asArray(converting: converting)
    }

    public func asDictionary(converting: Bool = false) throws -> [String: Map] {
        return try map.asDictionary(converting: converting)
    }
}

// MARK: Inferred

extension Optional where Wrapped : MapRepresentable {
    public func asInferred<T : MapInitializable>(converting: Bool = false) throws -> T {
        return try map.asInferred(converting: converting)
    }
}
