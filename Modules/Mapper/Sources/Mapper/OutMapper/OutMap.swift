public protocol OutMap {

    static var blank: Self { get }

    mutating func set(_ map: Self, at indexPath: IndexPathElement) throws
    mutating func set(_ map: Self, at indexPath: [IndexPathElement]) throws

    static func fromArray(_ array: [Self]) -> Self?
    static func from<T>(_ value: T) -> Self?

}
