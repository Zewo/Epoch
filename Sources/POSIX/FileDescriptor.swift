#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif


/// Get status flags
///
/// - Parameter fileDescriptor: File descriptor from which the status flags will be retrieved
/// - Returns: Status flags
///
/// - Throws: The following errors might be thrown:
///   #### SystemError.badFileDescriptor
///   Thrown when `fileDescriptor` is not an open file descriptor.
///   #### VeniceError.permissionDenied
///   Thrown when the operation is prohibited by locks held by other processes.
public func statusflags(fileDescriptor: Int32) throws -> Int32 {
    let flags = fcntl(fileDescriptor, F_GETFL, 0)

    if flags == -1 {
        throw SystemError.lastOperationError
    }

    return flags
}


/// Configure file descriptor as non-blocking.
///
/// When a file descriptor is configured as non-blocking, calls to `read` and `write` will
/// throw `SystemError.operationWouldBlock` if the operation would block.
///
/// - Parameter fileDescriptor: File descriptor which will be configured as non-blocking.
///
/// - Throws: The following errors might be thrown:
///   #### SystemError.badFileDescriptor
///   Thrown when `fileDescriptor` is not an open file descriptor.
///   #### VeniceError.permissionDenied
///   Thrown when the operation is prohibited by locks held by other processes.
public func setNonBlocking(fileDescriptor: Int32) throws {
    let flags = try statusflags(fileDescriptor: fileDescriptor)

    guard fcntl(fileDescriptor, F_SETFL, flags | O_NONBLOCK) == 0 else {
        throw SystemError.lastOperationError
    }
}


/// Closes a file descriptor, so that it no longer refers to any
/// file and may be reused.  Any record locks held on the
/// file it was associated with, and owned by the process, are removed
/// (regardless of the file descriptor that was used to obtain the lock).
///
/// If `fileDescriptor` is the last file descriptor referring to the underlying open
/// file description, the resources associated with the
/// open file description are freed; if the file descriptor was the last
/// reference to a file which has been removed using `unlink`, the file
/// is deleted.
///
/// - Parameter fileDescriptor: File descriptor which will be closed.
///
/// - Throws: The following errors might be thrown:
///   #### SystemError.badFileDescriptor
///   Thrown when `fileDescriptor` is not an open file descriptor.
///   #### SystemError.interruptedSystemCall
///   Thrown when the call was interrupted by a signal.
///   #### SystemError.inputOutputError
///   Thrown when an I/O error occurred.
public func close(fileDescriptor: Int32) throws {
    guard close(fileDescriptor) == 0 else {
        throw SystemError.lastOperationError
    }
}
