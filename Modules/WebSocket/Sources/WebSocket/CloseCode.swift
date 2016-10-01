public enum CloseCode : Equatable {
    case normal
    case goingAway
    case protocolError
    case unsupported
    case noStatus
    case abnormal
    case unsupportedData
    case policyViolation
    case tooLarge
    case missingExtension
    case internalError
    case serviceRestart
    case tryAgainLater
    case tlsHandshake
    case raw(UInt16)

    init(code: UInt16) {
        switch code {
        case 1000: self = .normal
        case 1001: self = .goingAway
        case 1002: self = .protocolError
        case 1003: self = .unsupported
        case 1005: self = .noStatus
        case 1006: self = .abnormal
        case 1007: self = .unsupportedData
        case 1008: self = .policyViolation
        case 1009: self = .tooLarge
        case 1010: self = .missingExtension
        case 1011: self = .internalError
        case 1012: self = .serviceRestart
        case 1013: self = .tryAgainLater
        case 1015: self = .tlsHandshake
        default:   self = .raw(UInt16(code))
        }
    }

    var code: UInt16 {
        switch self {
        case .normal:           return 1000
        case .goingAway:        return 1001
        case .protocolError:    return 1002
        case .unsupported:      return 1003
        case .noStatus:         return 1005
        case .abnormal:         return 1006
        case .unsupportedData:  return 1007
        case .policyViolation:  return 1008
        case .tooLarge:         return 1009
        case .missingExtension: return 1010
        case .internalError:    return 1011
        case .serviceRestart:   return 1012
        case .tryAgainLater:    return 1013
        case .tlsHandshake:     return 1015
        case .raw(let code):    return code
        }
    }

    var isValid: Bool {
        let code = self.code

        if code >= 1000 && code <= 5000 {
            return code != 1004 && code != 1005 && code != 1006 && code != 1014 && code != 1015
                && code != 1016 && code != 1100 && code != 2000 && code != 2999
        }

        return false
    }
}

public func == (lhs: CloseCode, rhs: CloseCode) -> Bool {
    return lhs.code == rhs.code
}
