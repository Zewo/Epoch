public protocol InMapperProtocol {
    
    associatedtype Source: InMap
    associatedtype IndexPath: IndexPathElement
    
    var source: Source { get }

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
    
    fileprivate func dive(to indexPath: [IndexPath]) throws -> Source {
        if let value = source.get(at: indexPath) {
            return value
        } else {
            throw InMapperError.noValue(forIndexPath: indexPath)
        }
    }
    
    fileprivate func get<T>(from source: Source) throws -> T {
        if let value: T = source.get() {
            return value
        } else {
            throw InMapperError.wrongType(T.self)
        }
    }
    
    fileprivate func array(from source: Source) throws -> [Source] {
        if let array = source.asArray {
            return array
        } else {
            throw InMapperError.cannotRepresentAsArray
        }
    }
    
    fileprivate func rawRepresent<T: RawRepresentable>(_ source: Source) throws -> T {
        let raw: T.RawValue = try get(from: source)
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

public struct InMapper<Source: InMap, Keys: IndexPathElement>: InMapperProtocol {
    
    public let source: Source
    public typealias IndexPath = Keys
    
    public init(of source: Source) {
        self.source = source
    }
    
}

public struct ContextualInMapper<Source: InMap, Keys: IndexPathElement, Context>: InMapperProtocol {
    
    public let source: Source
    public let context: Context?
    public typealias IndexPath = Keys
    
    public init(of source: Source, context: Context?) {
        self.source = source
        self.context = context
    }
    
    public func map<T: InMappableWithContext>(from indexPath: IndexPath...) throws -> T
        where T.Context == Context {
            let leveled = try dive(to: indexPath)
            return try T(mapper: ContextualInMapper<Source, T.Keys, T.Context>(of: leveled, context: self.context))
    }
    
    public func mapArray<T: InMappableWithContext>(from indexPath: IndexPath...) throws -> [T]
        where T.Context == Context {
            let leveled = try dive(to: indexPath)
            let array = try self.array(from: leveled)
            return try array.map({ try T(mapper: ContextualInMapper<Source, T.Keys, T.Context>(of: $0, context: self.context)) })
    }
    
}

public typealias StringInMapper<Source: InMap> = InMapper<Source, String>
public typealias StringContextualInMapper<Source: InMap, Context> = ContextualInMapper<Source, String, Context>

