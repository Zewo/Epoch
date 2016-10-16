
/// Data type from which strongly-typed instances can be mapped.
public protocol InMap {

    
    /// Returns instance of the same type for given index path.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - returns: `Self` instance if available; `nil` otherwise.
    func get(at indexPath: IndexPathValue) -> Self?
    
    
    /// Returns instance of the same type for given index path.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - returns: `Self` instance if available; `nil` otherwise.
    func get(at indexPath: [IndexPathValue]) -> Self?

    
    /// The representation of `self` as an array of `Self`; `nil` if `self` is not an array.
    func asArray() -> [Self]?
    
    /// Returns representation of `self` as desired `T`, if possible.
    func get<T>() -> T?
    
    /// Returns representation of `self` as `Int`, if possible.
    var int: Int? { get }
    
    /// Returns representation of `self` as `Double`, if possible.
    var double: Double? { get }
    
    /// Returns representation of `self` as `Bool`, if possible.
    var bool: Bool? { get }
    
    /// Returns representation of `self` as `String`, if possible.
    var string: String? { get }

}

extension InMap {

    /// Returns instance of the same type for given index path.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - returns: `Self` instance if available; `nil` otherwise.
    public func get(at indexPath: [IndexPathValue]) -> Self? {
        var result = self
        for index in indexPath {
            if let deeped = result.get(at: index) {
                result = deeped
            } else {
                return nil
            }
        }
        return result
    }

}
