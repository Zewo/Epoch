public enum Operator {
    case equal

    case greaterThan
    case greaterThanOrEqual

    case lessThan
    case lessThanOrEqual
    case contains
    case containedIn
}

extension Operator: StatementStringRepresentable {
    public var sqlString: String {
        switch self {
        case .equal:
            return "="
        case .greaterThan:
            return ">"
        case .greaterThanOrEqual:
            return ">="
        case .lessThan:
            return "<"
        case .lessThanOrEqual:
            return "<="
        case .contains:
            return "CONTAINS"
        case .containedIn:
            return "IN"
        }
    }
}
