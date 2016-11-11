/// Data type to which strongly-typed instances can be mapped.
public protocol OutMap {
    
    /// Blank state of the map.
    static var blank: Self { get }

    /// Sets value to given index path.
    ///
    /// - parameter map:       value to be set.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: throw if value cannot be set for some reason.
    mutating func set(_ map: Self, at indexPath: IndexPathValue) throws
    
    /// Sets value to given index path.
    ///
    /// - parameter map:       value to be set.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: throw if value cannot be set for some reason.
    mutating func set(_ map: Self, at indexPath: [IndexPathValue]) throws
    
    /// Creates instance from array of instances of the same type.
    ///
    /// - returns: instance of the same type as array element. `nil` if such conversion cannot be done.
    static func fromArray(_ array: [Self]) -> Self?
    
    /// Creates instance from any given type.
    ///
    /// - parameter value: input value.
    ///
    /// - returns: instance from the given value. `nil` if conversion cannot be done.
    static func from<T>(_ value: T) -> Self?
    
    
    /// Creates instance of `Self` from `Int`.
    ///
    /// - parameter int: input value.
    ///
    /// - returns: instance from the given `Int`. `nil` if conversion cannot be done.
    static func from(_ int: Int) -> Self?
    
    /// Creates instance of `Self` from `Double`.
    ///
    /// - parameter int: input value.
    ///
    /// - returns: instance from the given `Double`. `nil` if conversion cannot be done.
    static func from(_ double: Double) -> Self?
    
    /// Creates instance of `Self` from `Bool`.
    ///
    /// - parameter int: input value.
    ///
    /// - returns: instance from the given `Bool`. `nil` if conversion cannot be done.
    static func from(_ bool: Bool) -> Self?
    
    /// Creates instance of `Self` from `String`.
    ///
    /// - parameter int: input value.
    ///
    /// - returns: instance from the given `String`. `nil` if conversion cannot be done.
    static func from(_ string: String) -> Self?

}

public enum OutMapError : Error {
    case deepSetIsNotImplementedYet
}

extension OutMap {
    mutating public func set(_ map: Self, at indexPath: [IndexPathValue]) throws {
        let count = indexPath.count
        switch count {
        case 0:
            self = map
        case 1:
            try set(self, at: indexPath[0])
        default:
            throw OutMapError.deepSetIsNotImplementedYet
        }
    }
}
