public protocol QueryRendererProtocol {

    static func renderStatement(_ statement: Select) -> String

    static func renderStatement(_ statement: Update) -> String

    static func renderStatement(_ statement: Insert, forReturningInsertedRows returnInsertedRows: Bool) -> String

    static func renderStatement(_ statement: Delete) -> String
}

public extension QueryRendererProtocol {
    static func composePredicate(_ predicate: Predicate) -> String {
        switch predicate {
        case .expression(let left, let op, let right):
            var components = [composeParameter(left), op.sqlString]

            switch op {
            case .containedIn, .contains:
                components.append("(\(composeParameter(right)))")
                break
            default:
                components.append(composeParameter(right))
            }

            return components.joined(separator: " ")

        case .and(let predicates):
            return "(\(predicates.map { composePredicate($0) }.joined(separator: " AND ")))"
        case .or(let predicates):
            return "(\(predicates.map { composePredicate($0) }.joined(separator: " OR ")))"
        case .not(let predicate):
            return "NOT \(composePredicate(predicate))"
        }
    }

    static func composeParameter(_ parameter: Parameter) -> String {
        switch parameter {
        case .field(let field):
            return field.qualifiedName
        case .function(let function):
            return function.sqlString
        case .query(let select):
            return "\(renderStatement(select))"
        case .value:
            return "%@"
        case .null:
            return "%@"
        case .values(let values):
            return values.map { _ in "%@" }.joined(separator: ", ")
        }
    }
}
