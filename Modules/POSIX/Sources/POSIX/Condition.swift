#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

/// A wrapper for the pthread_cond_t type.
public final class Condition {
    internal var condition = pthread_cond_t()

    /**
     Creates a condition using the default attributes
     */
    public init() throws {
        // TOOD: Don't use default attributes
        let result = pthread_cond_init(&condition, nil)

        guard result == 0 else {
            throw SystemError(errorNumber: result)!
        }
    }

    deinit {
        pthread_cond_destroy(&condition)
    }

    /**
     Resolves the condition, unblocking threads (single or all, depending on `globally`) waiting for the condition.

     - parameter globally: If true, then all threads waiting on the condition are unblocked. Otherwise, only unblocks a single thread. Defaults to false.
     */
    public func resolve(globally: Bool = false) {
        if globally {
            pthread_cond_broadcast(&condition)
        } else {
            pthread_cond_signal(&condition)
        }
    }
}
