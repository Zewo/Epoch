public protocol FieldInfoProtocol: CustomStringConvertible {
    var name: String { get }
    var index: Int { get }
}

public extension FieldInfoProtocol {
    public var description: String {
        return name
    }
}
