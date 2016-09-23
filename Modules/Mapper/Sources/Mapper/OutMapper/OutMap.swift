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
    mutating func set(_ map: Self, at indexPath: IndexPathElement) throws
    
    /// Sets value to given index path.
    ///
    /// - parameter map:       value to be set.
    /// - parameter indexPath: path to set value to.
    ///
    /// - throws: throw if value cannot be set for some reason.
    mutating func set(_ map: Self, at indexPath: [IndexPathElement]) throws
    
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

}
