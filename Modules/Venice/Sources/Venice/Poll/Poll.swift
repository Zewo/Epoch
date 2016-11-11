import CLibvenice

public enum PollError : Error {
    case timeout
    case failure
}

public struct PollEvent : OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let read  = PollEvent(rawValue: Int(FDW_IN))
    public static let write = PollEvent(rawValue: Int(FDW_OUT))
}

/// Polls file descriptor for events
public func poll(_ fileDescriptor: FileDescriptor, events: PollEvent, deadline: Double) throws -> PollEvent {
    let event = mill_fdwait_(fileDescriptor, Int32(events.rawValue), deadline.int64milliseconds, "pollFileDescriptor")

    if event == 0 {
        throw PollError.timeout
    }

    if event == FDW_ERR {
        throw PollError.failure
    }

    return PollEvent(rawValue: Int(event))
}
