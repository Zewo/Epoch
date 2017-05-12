public struct Update: PredicatedQuery {
    public var predicate: Predicate? = nil

    public private(set) var valuesByField: [QualifiedField: Value?] = [:]

    public let tableName: String

    public init(_ tableName: String) {
        self.tableName = tableName
    }

    public mutating func set<T: ValueConvertible>(_ field: QualifiedField, _ value: T?) {
        valuesByField[field] = value?.sqlValue
    }

    public mutating func set(_ dict: [QualifiedField: ValueConvertible?]) {
        for (key, value) in dict {
            valuesByField[key] = value?.sqlValue
        }
    }
}

extension Update: StatementParameterListConvertible {
    public var sqlParameters: [Value?] {
        // order matters here. we assume that queries rendered as
        // UPDATE <table> SET <values> WHERE <predicate>
        // therefore, value parameters go first, with predicate parameters following them
        var parameters = [Value?]()

        parameters += valuesByField.values

        if let predicate = predicate {
            parameters += predicate.sqlParameters
        }

        return parameters
    }
}
