public struct QueryRenderer: QueryRendererProtocol {
    public static func renderStatement(_ statement: Select) -> String {
        var components = [String]()

        components.append("SELECT")

        var fieldComponents = [String]()

        for field in statement.fields {
            switch field {
            case .string(let string):
                fieldComponents.append(string)
                break
            case .subquery(let subquery, alias: let alias):
                fieldComponents.append("(\(renderStatement(subquery))) as \(alias)")
                break
            case .field(let field):
                fieldComponents.append(field.qualifiedName)
                break
            case .function(let function, let alias):
                fieldComponents.append("\(function.sqlString) as \(alias)")
                break
            }
        }

        components.append(fieldComponents.joined(separator: ", "))
        components.append("FROM")


        var sourceComponents = [String]()

        for source in statement.from {
            switch source {
            case .string(let string):
                sourceComponents.append(string)
                break
            case .subquery(let subquery, alias: let alias):
                sourceComponents.append("\(renderStatement(subquery)) as \(alias)")
                break
            case .field(let field):
                sourceComponents.append(field.qualifiedName)
                break
            case .function(let function, let alias):
                fieldComponents.append("\(function.sqlString) as \(alias)")
                break
            }
        }

        components.append(sourceComponents.joined(separator: ", "))

        if !statement.joins.isEmpty {
            components.append(statement.joins.sqlStringJoined(separator: " "))
        }

        if let predicate = statement.predicate {
            components.append("WHERE")
            components.append(composePredicate(predicate))
        }

        if !statement.order.isEmpty {
            components.append(statement.order.sqlStringJoined(separator: ", "))
        }

        if let limit = statement.limit {
            components.append("LIMIT \(limit)")
        }

        if let offset = statement.offset {
            components.append("OFFSET \(offset)")
        }

        return components.joined(separator: " ")
    }

    public static func renderStatement(_ statement: Update) -> String {
        var components = ["UPDATE", statement.tableName, "SET"]


        components.append(
            statement.valuesByField.map {
                return "\($0.key.unqualifiedName) = %@"
                }.joined(separator: ", ")
        )

        if let predicate = statement.predicate {
            components.append("WHERE")
            components.append(composePredicate(predicate))
        }

        return components.joined(separator: " ")
    }

    public static func renderStatement(_ statement: Insert, forReturningInsertedRows returnInsertedRows: Bool) -> String {
        var components = ["INSERT INTO", statement.tableName]

        components.append(
            "(\(statement.valuesByField.keys.map { $0.unqualifiedName }.joined(separator: ", ")))"
        )

        components.append("VALUES")

        components.append(
            "(\(statement.valuesByField.values.map { _ in "%@" }.joined(separator: ", ")))"
        )

        if returnInsertedRows {
            components.append("RETURNING *")
        }

        return components.joined(separator: " ")
    }

    public static func renderStatement(_ statement: Delete) -> String {
        var components = ["DELETE FROM", statement.tableName]

        if let predicate = statement.predicate {
            components.append("WHERE")
            components.append(composePredicate(predicate))
        }

        return components.joined(separator: " ")
    }
}
