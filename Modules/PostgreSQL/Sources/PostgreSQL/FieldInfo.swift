@_exported import SQL

public struct FieldInfo: SQL.FieldInfoProtocol {
    public let name: String
    public let index: Int

    init(name: String, index: Int) {
        self.name = name
        self.index = index
    }
}
