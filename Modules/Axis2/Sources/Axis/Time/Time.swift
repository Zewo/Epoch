#if os(Linux)
    import Glibc
    var ts = timespec()
#else
    import Darwin.C
    var factor: Double = {
        var mtid = mach_timebase_info_data_t()
        mach_timebase_info(&mtid)
        return Double(mtid.numer) / Double(mtid.denom) / 1E9
    }()
#endif

/// Absolute time in seconds
public func now() -> Double {
    #if os(Linux)
        clock_gettime(CLOCK_MONOTONIC, &ts)
        return Double(ts.tv_sec) + Double(ts.tv_nsec) / 1E9
     #else
        return Double(mach_absolute_time()) * factor
    #endif
}

extension Double {
    /// Interval of `self` from now.
    public func fromNow() -> Double {
        return now() + self
    }
}

public protocol TimeUnitRepresentable {
    var seconds: Double { get }
}

extension TimeUnitRepresentable {
    public var milliseconds: Double {
        if self.seconds == .never {
            return .never
        }
        return self.seconds / 1000
    }
    public var millisecond: Double {
        return self.milliseconds
    }
    public var second: Double {
        return self.seconds
    }
    public var minutes: Double {
        if self.seconds == .never {
            return .never
        }
        return self.seconds * 60
    }
    public var minute: Double {
        return self.minutes
    }
    public var hours: Double {
        if self.seconds == .never {
            return .never
        }
        return self.minutes * 60
    }
    public var hour: Double {
        return self.hours
    }
}

extension Double {
    public var int64milliseconds: Int64 {
        return Int64(self * 1000)
    }
}

extension Double : TimeUnitRepresentable {
    public var seconds: Double {
        return self
    }
}

extension Int : TimeUnitRepresentable {
    public var seconds: Double {
        return Double(self)
    }
}

extension Double {
    public static var never: Double {
        return -1
    }
}
