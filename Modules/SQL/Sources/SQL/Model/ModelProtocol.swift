public protocol ModelField: TableField {
    static var primaryKey: Self { get }
}

public protocol ModelProtocol: TableProtocol, TableRowConvertible {
    associatedtype PrimaryKey: Hashable, ValueConvertible
    associatedtype Field: ModelField

    func serialize() -> [Field: ValueConvertible?]

    func willSave() throws
    func didSave()

    func willUpdate() throws
    func didUpdate()

    func willCreate() throws
    func didCreate()

    func willDelete() throws
    func didDelete()

    func willRefresh() throws
    func didRefresh()
}

public extension ModelProtocol {
    public func willSave() throws {}
    public func didSave() {}

    public func willUpdate() throws {}
    public func didUpdate() {}

    public func willCreate() throws {}
    public func didCreate() {}

    public func willDelete() throws {}
    public func didDelete() {}

    public func willRefresh() throws {}
    public func didRefresh() {}
}

public struct EntityError: Error, CustomStringConvertible {
    public let description: String

    public init(_ description: String) {
        self.description = description
    }
}
