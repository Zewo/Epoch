public indirect enum Predicate {
    case expression(left: Parameter, operator: Operator, right: Parameter)
    case and([Predicate])
    case or([Predicate])
    case not(Predicate)
}

extension Predicate: StatementParameterListConvertible {
    public var sqlParameters: [Value?] {
        switch self {
        case .expression(let left, _, let right):
            return left.sqlParameters + right.sqlParameters
        case .and(let predicates):
            return predicates.flatMap { $0.sqlParameters }
        case .or(let predicates):
            return predicates.flatMap { $0.sqlParameters }
        case .not(let predicate):
            return predicate.sqlParameters
        }
    }
}

public prefix func ! (predicate: Predicate) -> Predicate {
    return .not(predicate)
}


public func == (lhs: ParameterConvertible?, rhs: ParameterConvertible?) -> Predicate {
    return .expression(left: lhs?.sqlParameter ?? .null, operator: .equal, right: rhs?.sqlParameter ?? .null)
}

public func > (lhs: ParameterConvertible?, rhs: ParameterConvertible?) -> Predicate {
    return .expression(left: lhs?.sqlParameter ?? .null, operator: .greaterThan, right: rhs?.sqlParameter ?? .null)
}

public func < (lhs: ParameterConvertible?, rhs: ParameterConvertible?) -> Predicate {
    return .expression(left: lhs?.sqlParameter ?? .null, operator: .lessThan, right: rhs?.sqlParameter ?? .null)
}

public func >= (lhs: ParameterConvertible?, rhs: ParameterConvertible?) -> Predicate {
    return .expression(left: lhs?.sqlParameter ?? .null, operator: .greaterThanOrEqual, right: rhs?.sqlParameter ?? .null)
}

public func <= (lhs: ParameterConvertible?, rhs: ParameterConvertible?) -> Predicate {
    return .expression(left: lhs?.sqlParameter ?? .null, operator: .lessThanOrEqual, right: rhs?.sqlParameter ?? .null)
}

// Contains

extension ParameterConvertible {
    public func contains(_ values: [ValueConvertible?]) -> Predicate {
        return contains(values.map { $0?.sqlValue })
    }

    public func contains(_ values: ValueConvertible?...) -> Predicate {
        return contains(values)
    }

    public func contains(_ values: [Value?]) -> Predicate {
        return .expression(left: self.sqlParameter, operator: .contains, right: .values(values))
    }

    public func contains(_ values: Value?...) -> Predicate {
        return contains(values)
    }
}

// Contains

extension ParameterConvertible {
    public func containedIn(_ values: [ValueConvertible?]) -> Predicate {
        return containedIn(values.map { $0?.sqlValue })
    }

    public func containedIn(_ values: ValueConvertible?...) -> Predicate {
        return containedIn(values)
    }

    public func containedIn(_ values: [Value?]) -> Predicate {
        return .expression(left: self.sqlParameter, operator: .containedIn, right: .values(values))
    }

    public func containedIn(_ values: Value?...) -> Predicate {
        return containedIn(values)
    }

    public func isNull() -> Predicate {
        return .expression(left: self.sqlParameter, operator: .equal, right: .null)
    }

    public func isNotNulll() -> Predicate {
        return .not(isNull())
    }
}


// MARK: Compound predicate

public func && (lhs: Predicate, rhs: Predicate) -> Predicate {
    return .and([lhs, rhs])
}

public func || (lhs: Predicate, rhs: Predicate) -> Predicate {
    return .or([lhs, rhs])
}

// Predicated query

public protocol PredicatedQuery {
    var predicate: Predicate? { get set }
}

public extension PredicatedQuery {
    public mutating func filter(_ value: Predicate)  {
        guard let existing = predicate else {
            predicate = value
            return
        }

        predicate = .and([existing, value])
    }

    public func filtered(_ value: Predicate) -> Self {
        var new = self
        new.filter(value)
        return new
    }
}
