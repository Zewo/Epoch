
/// Data type from which strongly-typed instances can be mapped.
public protocol InMap {

    
    /// Returns instance of the same type for given index path.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - returns: `Self` instance if available; `nil` otherwise.
    func get(at indexPath: IndexPathElement) -> Self?
    
    
    /// Returns instance of the same type for given index path.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - returns: `Self` instance if available; `nil` otherwise.
    func get(at indexPath: [IndexPathElement]) -> Self?

    
    /// The representation of `self` as an array of `Self`; `nil` if `self` is not an array.
    func asArray() -> [Self]?
    
    /// Returns representation of `self` as desired `T`, if possible.
    func get<T>() -> T?

}

extension InMap {

    /// Returns instance of the same type for given index path.
    ///
    /// - parameter indexPath: path to desired value.
    ///
    /// - returns: `Self` instance if available; `nil` otherwise.
    public func get(at indexPath: [IndexPathElement]) -> Self? {
        var result = self
        for index in indexPath {
            if let deeped = result.get(at: index) {
                result = deeped
            } else {
                break
            }
        }
        return result
    }

}
