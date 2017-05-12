public protocol ParameterConvertible {
    var sqlParameter: Parameter { get }
}

public enum Parameter {

    case field(QualifiedField)
    case value(Value?)
    case values([Value?])
    case function(Function)
    case query(Select)
    case null
}

extension Parameter: StatementParameterListConvertible {
    public var sqlParameters: [Value?] {
        switch self {
        case .field:
            return []
        case .value(let value):
            return [value]
        case .values(let values):
            return values
        case .function:
            return []
        case .query(let select):
            return select.sqlParameters
        case .null:
            return [nil]
        }
    }
}
