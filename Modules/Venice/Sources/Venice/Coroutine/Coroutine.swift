import CLibvenice

public typealias PID = pid_t

/// Runs the expression in a lightweight coroutine.
public func coroutine(_ routine: @escaping (Void) -> Void) {
    var _routine = routine
    CLibvenice.co(&_routine, { routinePointer in
        routinePointer!.assumingMemoryBound(to: ((Void) -> Void).self).pointee()
    }, "co")
}

/// Runs the expression in a lightweight coroutine.
public func coroutine(_ routine: @autoclosure @escaping  (Void) -> Void) {
    var _routine: (Void) -> Void = routine
    CLibvenice.co(&_routine, { routinePointer in
        routinePointer!.assumingMemoryBound(to: ((Void) -> Void).self).pointee()
    }, "co")
}

/// Runs the expression in a lightweight coroutine.
public func co(_ routine: @escaping (Void) -> Void) {
    coroutine(routine)
}

/// Runs the expression in a lightweight coroutine.
public func co(_ routine: @autoclosure @escaping (Void) -> Void) {
    var _routine: (Void) -> Void = routine
    CLibvenice.co(&_routine, { routinePointer in
        routinePointer!.assumingMemoryBound(to: ((Void) -> Void).self).pointee()
    }, "co")
}

/// Runs the expression in a lightweight coroutine after the given duration.
public func after(_ napDuration: Double, routine: @escaping (Void) -> Void) {
    co {
        nap(for: napDuration)
        routine()
    }
}

/// Runs the expression in a lightweight coroutine periodically. Call done() to leave the loop.
public func every(_ napDuration: Double, routine: @escaping (_ done: (Void) -> Void) -> Void) {
    co {
        var done = false
        while !done {
            nap(for: napDuration)
            routine {
                done = true
            }
        }
    }
}

/// Sleeps for duration.
public func nap(for duration: Double) {
    mill_msleep_(duration.fromNow().int64milliseconds, "nap")
}

/// Wakes up at deadline.
public func wake(at deadline: Double) {
    mill_msleep_(deadline.int64milliseconds, "wakeUp")
}

/// Passes control to other coroutines.
public var yield: Void {
    mill_yield_("yield")
}

/// Fork the current process.
public func fork() -> PID {
    return mill_mfork_()
}

/// Get the number of logical CPU cores available. This might return a bigger number than the physical CPU Core number if the CPU supports hyper-threading.
public var logicalCPUCount: Int {
    return Int(mill_number_of_cores())
}

public func dump() {
    goredump()
}
