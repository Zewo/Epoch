public enum ConfigurationError : Error {
    case invalidArgument(description: String)
}

extension ConfigurationError : CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidArgument(let description):
            return description
        }
    }
}

public struct Configuration {
    public static func commandLineArguments(_ arguments: [String] = CommandLine.arguments) throws -> Map {
        let arguments = Array(arguments.dropFirst())
        var parameters: Map = [:]

        var currentParameter = ""
        var hasParameter = false
        var value: Map = nil
        var i = 0

        while i < arguments.count {
            if arguments[i].has(prefix: "-") {
                if !hasParameter {
                    currentParameter = String(Array(arguments[i].characters).suffix(from: 1))
                    hasParameter = true
                    i += 1
                } else {
                    value = true
                    let indexPath = currentParameter.indexPath()
                    try parameters.set(value, for: indexPath)
                    hasParameter = false
                }
                continue
            }
            if hasParameter {
                let value = parse(value: arguments[i])
                let indexPath = currentParameter.indexPath()
                try parameters.set(value, for: indexPath)
                hasParameter = false
                i += 1
            } else {
                throw ConfigurationError.invalidArgument(description: "\(arguments[i]) is a malformed parameter. Parameters should be provided in the format -parameter [value].")
            }
        }

        if hasParameter {
            let indexPath = currentParameter.indexPath()
            try parameters.set(true, for: indexPath)
        }

        if parameters == [:] {
            return nil
        }

        return parameters
    }

    static func parse(value: String) -> Map {
        if isNull(value) {
            return .null
        }

        if let intValue = Int(value) {
            return .int(intValue)
        }

        if let doubleValue = Double(value) {
            return .double(doubleValue)
        }

        if let boolValue = convertToBool(value) {
            return .bool(boolValue)
        }

        return .string(value)
    }

    static func isNull(_ string: String) -> Bool {
        switch string {
        case "NULL", "Null", "null", "NIL", "Nil", "nil":
            return true
        default:
            return false
        }
    }

    static func convertToBool(_ string: String) -> Bool? {
        switch string {
        case "TRUE", "True", "true", "YES", "Yes", "yes":
            return true
        case "FALSE", "False", "false", "NO", "No", "no":
            return false
        default:
            return nil
        }
    }
}
