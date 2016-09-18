public protocol InMapperProtocol {
    
    associatedtype Map: InMapProtocol
    associatedtype IndexPath: IndexPathElement
    
    var inMap: Map { get }

}

public enum InMapperError: Error {
    case noValue(forIndexPath: [IndexPathElement])
    case wrongType(Any.Type)
    case cannotInitializeFromRawValue(Any)
    case cannotRepresentAsArray
    case userDefinedError
    case validationFailed(with: Error?)
}

extension InMapperProtocol {
    
    fileprivate func dive(to indexPath: [IndexPath]) throws -> Map {
        if let value = inMap.get(at: indexPath) {
            return value
        } else {
            throw InMapperError.noValue(forIndexPath: indexPath)
        }
    }
    
    fileprivate func get<T>(from map: Map) throws -> T {
        if let value: T = map.get() {
            return value
        } else {
            throw InMapperError.wrongType(T.self)
        }
    }
    
    fileprivate func array(from map: Map) throws -> [Map] {
        if let array = map.asArray {
            return array
        } else {
            throw InMapperError.cannotRepresentAsArray
        }
    }
    
    fileprivate func rawRepresent<T: RawRepresentable>(_ map: Map) throws -> T {
        let raw: T.RawValue = try get(from: map)
        if let value = T(rawValue: raw) {
            return value
        } else {
            throw InMapperError.cannotInitializeFromRawValue(raw)
        }
    }
    
    public func map<T>(from indexPath: IndexPath...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try get(from: leveled)
    }
    
    public func map<T: InMappable>(from indexPath: IndexPath...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: InMapper(of: leveled))
    }
    
    public func map<T: InMappableWithContext>(from indexPath: IndexPath..., usingContext context: T.Context) throws -> T {
        let leveled = try dive(to: indexPath)
        return try T(mapper: ContextualInMapper(of: leveled, context: context))
    }
    
    public func map<T: RawRepresentable>(from indexPath: IndexPath...) throws -> T {
        let leveled = try dive(to: indexPath)
        return try rawRepresent(leveled)
    }
    
    public func mapArray<T>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try get(from: $0) })
    }
    
    public func mapArray<T: InMappable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: InMapper(of: $0)) })
    }
    
    public func mapArray<T: InMappableWithContext>(from indexPath: IndexPath..., usingContext context: T.Context) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try T(mapper: ContextualInMapper(of: $0, context: context)) })
    }
    
    public func mapArray<T: RawRepresentable>(from indexPath: IndexPath...) throws -> [T] {
        let leveled = try dive(to: indexPath)
        let array = try self.array(from: leveled)
        return try array.map({ try self.rawRepresent($0) })
    }
    
}

public struct InMapper<Map: InMapProtocol, Keys: IndexPathElement>: InMapperProtocol {
    
    public let inMap: Map
    public typealias IndexPath = Keys
    
    public init(of map: Map) {
        self.inMap = map
    }
    
}

public struct ContextualInMapper<Map: InMapProtocol, Keys: IndexPathElement, Context>: InMapperProtocol {
    
    public let inMap: Map
    public let context: Context?
    public typealias IndexPath = Keys
    
    public init(of map: Map, context: Context?) {
        self.inMap = map
        self.context = context
    }
    
    public func map<T: InMappableWithContext>(from indexPath: IndexPath...) throws -> T
        where T.Context == Context {
            let leveled = try dive(to: indexPath)
            return try T(mapper: ContextualInMapper<Map, T.Keys, T.Context>(of: leveled, context: self.context))
    }
    
    public func mapArray<T: InMappableWithContext>(from indexPath: IndexPath...) throws -> [T]
        where T.Context == Context {
            let leveled = try dive(to: indexPath)
            let array = try self.array(from: leveled)
            return try array.map({ try T(mapper: ContextualInMapper<Map, T.Keys, T.Context>(of: $0, context: self.context)) })
    }
    
}

public typealias StringInMapper<Map: InMapProtocol> = InMapper<Map, String>
public typealias StringContextualInMapper<Map: InMapProtocol, Context> = ContextualInMapper<Map, String, Context>

