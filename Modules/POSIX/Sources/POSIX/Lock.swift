#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/// A wrapper for the POSIX pthread_mutex_t type.
public final class Lock {
    internal var mutex = pthread_mutex_t()

    /**
     Creates a pthread_mutex using the default attributes.
     */
    public init() throws {
        // default attributes
        let result = pthread_mutex_init(&mutex, nil)

        guard result == 0 else {
            throw SystemError(errorNumber: result)!
        }
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    /**
     Acquires the lock for the duration of the closure. Releases afterwards. If
     lock is already acquired elsewhere, suspends execution until lock is released.

     - parameter closure: A closure returning a value of type T. Executed after
     the lock has been acquired.

     - returns: Returns the result of the closure

     - remarks: The closure can return `Void`, which is useful when there is need
     for a result.

     - note: If the closure throws an error, the lock is released befored returning.
     */
    public func withLock<T>(_ closure: () throws -> (T)) throws -> T {
        try acquire()
        defer { release() }
        return try closure()
    }

    /**
     Acquires the lock.

     - note: If lock is acquired by a different thread, current thread's execution
     is suspended until the lock is released.
     */
    public func acquire() throws {
        let result = pthread_mutex_lock(&mutex)

        guard result == 0 else {
            throw SystemError(errorNumber: result)!
        }
    }

    /**
     Releases the lock.

     - precondition: Lock is alreay acquired. Behavior is undefined otherwise.
     */
    public func release() {
        pthread_mutex_unlock(&mutex)
    }

    /**
     Suspends execution until the condition has been resolved.

     - note: Releases the lock while waiting, re-acquires afterwards.

     - precondition: Lock is already acquired. Behavior is undefined otherwise.
     */
    public func wait(for condition: Condition) {
        // TODO: handle spurious wakeups (can't find good documentation
        // for how to do this)
        pthread_cond_wait(&condition.condition, &mutex)
    }
}
