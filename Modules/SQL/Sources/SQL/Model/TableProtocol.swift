public protocol TableField: RawRepresentable, Hashable, ParameterConvertible {
    static var tableName: String { get }
}

public extension TableField {
    public var sqlParameter: Parameter {
        return .field(qualifiedField)
    }

    public var qualifiedField: QualifiedField {
        return QualifiedField("\(Self.tableName).\(self.rawValue)")
    }
}

public protocol TableProtocol {
    associatedtype Field: TableField

}

public extension TableProtocol where Self.Field.RawValue == String {

    public static func select(_ fields: Field...) -> Select {
        return Select(fields.map { $0.qualifiedField }, from: [Field.tableName])
    }

    public static func select(where predicate: Predicate) -> Select {
        return select.filtered(predicate)
    }

    public static var select: Select {
        return Select("*", from: Field.tableName)
    }

    public static func update(_ dict: [Field: ValueConvertible?]) -> Update {
        var translated = [QualifiedField: ValueConvertible?]()

        for (key, value) in dict {
            translated[key.qualifiedField] = value
        }

        var update = Update(Field.tableName)
        update.set(translated)

        return update
    }

    public static func insert(_ dict: [Field: ValueConvertible?]) -> Insert {
        var translated = [QualifiedField: ValueConvertible?]()

        for (key, value) in dict {
            translated[key.qualifiedField] = value
        }

        return Insert(Field.tableName, values: translated)
    }

    public static func delete(where predicate: Predicate) -> Delete {
        return Delete(from: Field.tableName).filtered(predicate)
    }

    public static var delete: Delete {
        return Delete(from: Field.tableName)
    }
}
