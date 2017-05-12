public struct Insert {
    public let valuesByField: [QualifiedField: Value?]

    public let tableName: String

    public init(_ tableName: String, values: [QualifiedField: Value?]) {
        self.tableName = tableName
        self.valuesByField = values
    }

    public init(_ tableName: String, values: [QualifiedField: ValueConvertible?]) {
        var transformed = [QualifiedField: Value?]()

        for (key, value) in values {
            transformed[key] = value?.sqlValue
        }

        self.init(tableName, values: transformed)
    }
}

extension Insert: StatementParameterListConvertible {
    public var sqlParameters: [Value?] {
        return Array(valuesByField.values)
    }
}
