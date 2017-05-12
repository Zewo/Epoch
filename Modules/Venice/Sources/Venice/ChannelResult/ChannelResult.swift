public enum ChannelResult<T> {
    case value(T)
    case error(Error)

    public var succeeded: Bool {
        switch self {
        case .value:
            return true
        default:
            return false
        }
    }

    public var failed: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }

    public func success(_ success: (T) -> Void) {
        switch self {
        case .value(let value):
            success(value)
        default:
            break
        }
    }

    public func failure(_ failure: (Error) -> Void) {
        switch self {
        case .error(let error):
            failure(error)
        default:
            break
        }
    }
}
