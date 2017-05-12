import CLibdill
import Foundation

public typealias Coroutine = Handle

///// Runs the expression in a lightweight coroutine.
@discardableResult
public func coroutine(file: String = #file, line: Int = #line, _ routine: @escaping (Void) throws -> Void) throws -> Coroutine {
    var routine = routine

    let result = co(nil, 0, &routine, file, Int32(line)) { pointer in
        do {
            try pointer!.assumingMemoryBound(to: ((Void) throws -> Void).self).pointee()
        } catch {
            print(error)

            for symbol in Thread.callStackSymbols {
                print(symbol)
            }
        }
    }

    guard result != -1 else {
        switch errno {
        case ECANCELED:
            throw VeniceError.canceled
        case ENOMEM:
            throw VeniceError.outOfMemory
        default:
            throw VeniceError.unexpected
        }
    }

    return Coroutine(handle: result)
}

/// Sleeps for duration.
public func nap(for duration: Duration) throws {
    try wakeUp(duration.fromNow())
}

/// Wakes up at deadline.
public func wakeUp(_ deadline: Deadline) throws {
    let result = msleep(deadline)

    guard result == 0 else {
        switch errno {
        case ECANCELED:
            throw VeniceError.canceled
        default:
            throw VeniceError.unexpected
        }
    }
}

/// Runs the expression in a lightweight coroutine after the given duration.
public func after(_ duration: Duration, routine: @escaping (ChannelResult<Void>) throws -> Void) throws -> Coroutine {
    return try coroutine {
        let result: ChannelResult<Void>

        do {
            try nap(for: duration)
            result = .value()
        } catch {
            result = .error(error)
        }

        try routine(result)
    }
}

/// Passes control to other coroutines.
public func yield() throws {
    let result = CLibdill.yield()

    guard result == 0 else {
        switch errno {
        case ECANCELED:
            throw VeniceError.canceled
        default:
            throw VeniceError.unexpected
        }
    }
}

/// Clean the file descriptor.
public func clean(fileDescriptor: FileDescriptor) {
    fdclean(fileDescriptor)
}
