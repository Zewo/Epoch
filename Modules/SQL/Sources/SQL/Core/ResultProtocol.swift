import Axis

public protocol ResultStatus {
    var successful: Bool { get }
}

public protocol ResultProtocol: Collection {
    associatedtype FieldInfo: FieldInfoProtocol

    func clear()

    var fieldsByName: [String: FieldInfo] { get }

    subscript(index: Int) -> Iterator.Element { get }

    var count: Int { get }

    func data(atRow rowIndex: Int, forFieldIndex fieldIndex: Int) -> Buffer?
}

extension ResultProtocol {

    public var fields: [FieldInfo] {
        return Array(fieldsByName.values)
    }

    public func index(ofFieldByName name: String) -> Int? {
        guard let field = fieldsByName[name] else {
            return nil
        }

        return field.index
    }

    public var startIndex: Int {
        return 0
    }

    public var endIndex: Int {
        return count
    }

    public func index(after: Int) -> Int {
        return after + 1
    }
}
