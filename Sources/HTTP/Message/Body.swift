import Core

public enum Body {
    public typealias Write = (WritableStream) throws -> Void
    
    case readable(ReadableStream)
    case writable(Write)
}

extension Body {
    public static var empty: Body {
        return .writable({ _ in })
    }
}

extension Body {
    public var isReadable: Bool {
        switch self {
        case .readable:
            return true
        default:
            return false
        }
    }
    
    public var readable: ReadableStream? {
        switch self {
        case let .readable(stream):
            return stream
        default:
            return nil
        }
    }
    
    public var isWritable: Bool {
        switch self {
        case .writable: return true
        default: return false
        }
    }
    
    public var writable: Write? {
        switch self {
        case let .writable(write):
            return write
        default:
            return nil
        }
    }
}
