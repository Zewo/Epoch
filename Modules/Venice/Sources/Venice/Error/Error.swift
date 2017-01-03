public enum VeniceError : Error {
    case canceled
    case invalidFileDescriptor
    case invalidHandle
    case invalidParameter
    case fileDescriptorBlockedInAnotherCoroutine
    case timeout
    case operationNotSupported
    case outOfMemory
    case channelIsDone
    case unexpected
}
