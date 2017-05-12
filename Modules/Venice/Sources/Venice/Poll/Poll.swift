import CLibdill

public enum PollEvent {
    case read
    case write
}

/// Polls file descriptor for events
public func poll(_ fileDescriptor: FileDescriptor, event: PollEvent, deadline: Deadline) throws {
    let result: Int32

    switch event {
    case .read:
        result = fdin(fileDescriptor, deadline)
    case .write:
        result = fdout(fileDescriptor, deadline)
    }

    guard result == 0 else {
        switch errno {
        case EBADF:
            throw VeniceError.invalidFileDescriptor
        case ECANCELED:
            throw VeniceError.canceled
        case EEXIST:
            throw VeniceError.fileDescriptorBlockedInAnotherCoroutine
        case ETIMEDOUT:
            throw VeniceError.timeout
        default:
            throw VeniceError.unexpected
        }
    }
}
