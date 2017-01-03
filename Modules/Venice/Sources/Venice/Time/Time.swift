import CLibdill

public typealias Duration = Int64
public typealias Deadline = Int64

/// Absolute time in seconds
public func now() -> Deadline {
    return CLibdill.now()
}

extension DeadlineRepresentable {
    /// Interval of `self` from now.
    public func fromNow() -> Deadline {
        return milliseconds + now()
    }
}

extension Deadline {
    public static var immediately: Deadline {
        return 0
    }

    public static var never: Deadline {
        return -1
    }
}

public protocol DeadlineRepresentable {
    var milliseconds: Deadline { get }
}

extension DeadlineRepresentable {
    public var millisecond: Deadline {
        if milliseconds == .never {
            return .never
        }

        return milliseconds
    }

    public var seconds: Deadline {
        if milliseconds == .never {
            return .never
        }

        return milliseconds * 1000
    }

    public var second: Deadline {
        if milliseconds == .never {
            return .never
        }

        return seconds
    }

    public var minutes: Deadline {
        if milliseconds == .never {
            return .never
        }

        return seconds * 60
    }

    public var minute: Deadline {
        if milliseconds == .never {
            return .never
        }

        return minutes
    }

    public var hours: Deadline {
        if milliseconds == .never {
            return .never
        }

        return minutes * 60
    }

    public var hour: Deadline {
        if milliseconds == .never {
            return .never
        }

        return hours
    }
}

extension Deadline : DeadlineRepresentable {
    public var milliseconds: Deadline {
        return self
    }
}

extension Int : DeadlineRepresentable {
    public var milliseconds: Deadline {
        return Deadline(self)
    }
}
