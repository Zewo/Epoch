#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum ThreadError: Error {
    case notEnoughResources
    case invalidReturnValue
}

/// A wrapper for the POSIX pthread_t type.
public final class PThread<T> {

    internal let thread: pthread_t
    private let context: ThreadContext

    private let keepAlive: Bool

    public var done: Bool { return context.done }

    /**
     Creates a new thread which immediately begins executing the passed routine.

     - parameter keepAlive: A boolean determining whether the thread execution should
     be canceled upon deinitialization of the created instance. Defaults to true.

     - parameter routine: A closure which is executed on a new thread. Errors thrown in the routine are thrown in the `join` method.

     - remarks: The routine can return `Void`, which is useful when there is need
     for a result.
     */
    public init(keepAlive: Bool = true, routine: @escaping () throws -> (T)) throws {

        let context = ThreadContext(routine: routine)

        #if os(Linux)
            let pthreadPointer = UnsafeMutablePointer<pthread_t>.allocate(capacity: 1)
            defer { pthreadPointer.deallocate(capacity: 1) }
        #else
            let pthreadPointer = UnsafeMutablePointer<pthread_t?>.allocate(capacity: 1)
            defer { pthreadPointer.deallocate(capacity: 1) }
        #endif

        let result = pthread_create(
            pthreadPointer,
            nil, // default attributes
            pthreadRunner,
            encode(context)
        )

        if result == EAGAIN {
            throw ThreadError.notEnoughResources
        }

        #if os(Linux)
            self.thread = pthreadPointer.pointee
        #else
            self.thread = pthreadPointer.pointee!
        #endif

        self.context = context
        self.keepAlive = keepAlive
    }

    deinit {
        pthread_detach(thread)
        if !keepAlive {
            abort()
        }
    }

    /**
     Suspends execution until the thread's routine has finished executing.

     - returns: Returns the result of the routine.
     */
    public func wait() throws -> T {
        var _out: UnsafeMutableRawPointer?
        pthread_join(thread, &_out)

        guard let out = _out else {
            throw ThreadError.invalidReturnValue
        }

        let result: Result<T> = decode(out)

        switch result {
        case .success(let t): return t
        case .failure(let e): throw e
        }
    }

    /**
     Stops the execution of the thread.

     - note: Cancelling only takes place after the cleanup (asynchronous) has finished.
     */
    public func abort() {
        pthread_cancel(thread)
    }
}

private enum Result<T> {
    case success(T)
    case failure(Error)

    init(of routine: () throws -> T) {
        do {
            self = try .success(routine())
        } catch {
            self = .failure(error)
        }
    }
}

private final class ThreadContext {
    var done = false
    let routine: () -> UnsafeMutableRawPointer?
    init<T>(routine: @escaping () throws -> T) {
        self.routine = {
            return encode(Result(of: routine))
        }
    }
}

private final class Box<T> {
    let value: T

    init(_ value: T) {
        self.value = value
    }
}

private func decode<T>(_ memory: UnsafeMutableRawPointer) -> T {
    // TODO: find a way to handle errors here
    let unmanaged = Unmanaged<Box<T>>.fromOpaque(memory)
    defer { unmanaged.release() }
    return unmanaged.takeUnretainedValue().value
}

private func encode<T>(_ t: T) -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(Box(t)).toOpaque()
}

// Two variations for portability, let compiler decide which one to use

private func pthreadRunner(context: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    // TODO: don't force unwrap
    let context = decode(context!) as ThreadContext
    let result = context.routine()
    context.done = true
    return result
}

private func pthreadRunner(context: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    return pthreadRunner(context: .some(context))
}
