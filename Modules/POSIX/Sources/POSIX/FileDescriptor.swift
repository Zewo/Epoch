#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public typealias FileDescriptor = Int32

public func statusflags(fileDescriptor: FileDescriptor) throws -> Int32 {
    let flags = fcntl(fileDescriptor, F_GETFL, 0)

    if flags == -1 {
        throw SystemError.lastOperationError
    }

    return flags
}

public func setNonBlocking(fileDescriptor: FileDescriptor) throws {
    let flags = try statusflags(fileDescriptor: fileDescriptor)

    guard fcntl(fileDescriptor, F_SETFL, flags | O_NONBLOCK) == 0 else {
        throw SystemError.lastOperationError
    }
}

public func close(fileDescriptor: FileDescriptor) throws {
    guard close(fileDescriptor) == 0 else {
        throw SystemError.lastOperationError
    }
}
