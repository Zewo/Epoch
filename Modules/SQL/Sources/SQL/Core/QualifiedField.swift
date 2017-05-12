public struct QualifiedField {
    public let unqualifiedName: String
    public var tableName: String?
    public var alias: String?

    public init(_ name: String, alias: String? = nil) {
        let components = name.split(separator: ".")
        if components.count == 2, let tableName = components.first, let fieldName = components.last {
            self.unqualifiedName = fieldName
            self.tableName = tableName
        }
        else {
            self.unqualifiedName = name
            self.tableName = nil
        }

        self.alias = alias
    }

    func alias(_ alias: String) -> QualifiedField {
        var new = self
        new.alias = alias
        return new
    }
}

extension QualifiedField: ParameterConvertible {
    public var sqlParameter: Parameter {
        return .field(self)
    }
}

public extension QualifiedField {
    public var qualifiedName: String {
        guard let tableName = tableName else {
            return unqualifiedName
        }
        return tableName + "." + unqualifiedName
    }
}

extension QualifiedField: Hashable {
    public var hashValue: Int {
        return qualifiedName.hashValue
    }
}

public func == (lhs: QualifiedField, rhs: QualifiedField) -> Bool {
    return lhs.hashValue == rhs.hashValue
}
