public protocol InMap {

    func get(at indexPath: IndexPathElement) -> Self?
    func get(at indexPath: [IndexPathElement]) -> Self?

    var asArray: [Self]? { get }

    func get<T>() -> T?

}

extension InMap {

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
