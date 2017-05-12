public struct Delete: PredicatedQuery {
    public var predicate: Predicate? = nil

    public let tableName: String

    public init(from tableName: String) {
        self.tableName = tableName
    }
}

extension Delete: StatementParameterListConvertible {
    public var sqlParameters: [Value?] {
        if let predicate = predicate {
            return predicate.sqlParameters
        }

        return []
    }
}
