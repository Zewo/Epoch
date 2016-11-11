extension Map : InMap {
    
    public func get(at indexPath: IndexPathValue) -> Map? {
        return try? self.get([indexPath])
    }
    
    public func asArray() -> [Map]? {
        if case .array(let array) = self {
            return array
        }
        return nil
    }
    
    public func get<T>() -> T? {
        return self.get()
    }
    
}

extension Map : OutMap {
    
    public static var blank: Map {
        return .dictionary([:])
    }
    
    public mutating func set(_ map: Map, at indexPath: IndexPathValue) throws {
        try self.set(map, for: indexPath)
    }
    
    public static func fromArray(_ array: [Map]) -> Map? {
        return .array(array)
    }
    
    public static func from<T>(_ value: T) -> Map? {
        if let representable = value as? MapRepresentable {
            return representable.map
        }
        return nil
    }
    
    public static func from(_ int: Int) -> Map? {
        return .int(int)
    }
    
    public static func from(_ double: Double) -> Map? {
        return .double(double)
    }
    
    public static func from(_ string: String) -> Map? {
        return .string(string)
    }
    
    public static func from(_ bool: Bool) -> Map? {
        return .bool(bool)
    }
    
}
