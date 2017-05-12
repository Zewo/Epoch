public enum Order {
    case asc(StatementStringRepresentable)
    case desc(StatementStringRepresentable)
}

extension Order: StatementStringRepresentable {
    public var sqlString: String {
        switch self {
        case .asc(let representable):
            return "\(representable.sqlString) ASC"
        case .desc(let representable):
            return "\(representable.sqlString) DESC"
        }
    }
}
