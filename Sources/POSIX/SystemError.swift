#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum SystemError : Error {
    case success
    
    case operationNotPermitted
    case noSuchFileOrDirectory
    case noSuchProcess
    case interruptedSystemCall
    case inputOutputError
    case deviceNotConfigured
    case argumentListTooLong
    case executableFormatError
    case badFileDescriptor
    case noChildProcesses
    case resourceDeadlockAvoided
    case cannotAllocateMemory
    case permissionDenied
    case badAddress

    case blockDeviceRequired

    case deviceOrResourceBusy
    case fileExists
    case crossDeviceLink
    case operationNotSupportedByDevice
    case notADirectory
    case isADirectory
    case invalidArgument
    case tooManyOpenFilesInSystem
    case tooManyOpenFiles
    case inappropriateInputOutputControlForDevice
    case textFileBusy
    case fileTooLarge
    case noSpaceLeftOnDevice
    case illegalSeek
    case readOnlyFileSystem
    case tooManyLinks
    case brokenPipe

    /* math software */
    case numericalArgumentOutOfDomain
    case resultTooLarge

    /* non-blocking and interrupt i/o */
    case resourceTemporarilyUnavailable
    case operationWouldBlock
    case operationNowInProgress
    case operationAlreadyInProgress

    /* ipc/network software -- argument errors */
    case socketOperationOnNonSocket
    case destinationAddressRequired
    case messageTooLong
    case protocolWrongTypeForSocket
    case protocolNotAvailable
    case protocolNotSupported

    case socketTypeNotSupported

    case operationNotSupported

    case protocolFamilyNotSupported

    case addressFamilyNotSupportedByProtocolFamily
    case addressAlreadyInUse
    case cannotAssignRequestedAddress

    /* ipc/network software -- operational errors */
    case networkIsDown
    case networkIsUnreachable
    case networkDroppedConnectionOnReset
    case softwareCausedConnectionAbort
    case connectionResetByPeer
    case noBufferSpaceAvailable
    case socketIsAlreadyConnected
    case socketIsNotConnected

    case cannotSendAfterSocketShutdown
    case tooManyReferences

    case operationTimedOut
    case connectionRefused

    case tooManyLevelsOfSymbolicLinks
    case fileNameTooLong

    case hostIsDown

    case noRouteToHost
    case directoryNotEmpty

    /* quotas & mush */
    case tooManyUsers

    case diskQuotaExceeded

    /* Network File System */
    case staleFileHandle
    case objectIsRemote

    case noLocksAvailable
    case functionNotImplemented

    case valueTooLargeForDefinedDataType

    case operationCanceled

    case identifierRemoved
    case noMessageOfDesiredType
    case illegalByteSequence

    case badMessage
    case multihopAttempted
    case noDataAvailable
    case linkHasBeenSevered
    case outOfStreamsResources
    case deviceNotAStream
    case protocolError
    case timerExpired

    case stateNotRecoverable
    case previousOwnerDied

    case other(errorNumber: Int32)
}

extension SystemError {
    public init(errorNumber: Int32) {
        switch errorNumber {
        case 0: self = .success

        case EPERM: self = .operationNotPermitted
        case ENOENT: self = .noSuchFileOrDirectory
        case ESRCH: self = .noSuchProcess
        case EINTR: self = .interruptedSystemCall
        case EIO: self = .inputOutputError
        case ENXIO: self = .deviceNotConfigured
        case E2BIG: self = .argumentListTooLong
        case ENOEXEC: self = .executableFormatError
        case EBADF: self = .badFileDescriptor
        case ECHILD: self = .noChildProcesses
        case EDEADLK: self = .resourceDeadlockAvoided
        case ENOMEM: self = .cannotAllocateMemory
        case EACCES: self = .permissionDenied
        case EFAULT: self = .badAddress

        case ENOTBLK: self = .blockDeviceRequired

        case EBUSY: self = .deviceOrResourceBusy
        case EEXIST: self = .fileExists
        case EXDEV: self = .crossDeviceLink
        case ENODEV: self = .operationNotSupportedByDevice
        case ENOTDIR: self = .notADirectory
        case EISDIR: self = .isADirectory
        case EINVAL: self = .invalidArgument
        case ENFILE: self = .tooManyOpenFilesInSystem
        case EMFILE: self = .tooManyOpenFiles
        case ENOTTY: self = .inappropriateInputOutputControlForDevice
        case ETXTBSY: self = .textFileBusy
        case EFBIG: self = .fileTooLarge
        case ENOSPC: self = .noSpaceLeftOnDevice
        case ESPIPE: self = .illegalSeek
        case EROFS: self = .readOnlyFileSystem
        case EMLINK: self = .tooManyLinks
        case EPIPE: self = .brokenPipe

        /* math software */
        case EDOM: self = .numericalArgumentOutOfDomain
        case ERANGE: self = .resultTooLarge

        /* non-blocking and interrupt i/o */
        case EAGAIN: self = .resourceTemporarilyUnavailable
        case EWOULDBLOCK: self = .operationWouldBlock
        case EINPROGRESS: self = .operationNowInProgress
        case EALREADY: self = .operationAlreadyInProgress

        /* ipc/network software -- argument errors */
        case ENOTSOCK: self = .socketOperationOnNonSocket
        case EDESTADDRREQ: self = .destinationAddressRequired
        case EMSGSIZE: self = .messageTooLong
        case EPROTOTYPE: self = .protocolWrongTypeForSocket
        case ENOPROTOOPT: self = .protocolNotAvailable
        case EPROTONOSUPPORT: self = .protocolNotSupported

        case ESOCKTNOSUPPORT: self = .socketTypeNotSupported

        case ENOTSUP: self = .operationNotSupported

        case EPFNOSUPPORT: self = .protocolFamilyNotSupported

        case EAFNOSUPPORT: self = .addressFamilyNotSupportedByProtocolFamily
        case EADDRINUSE: self = .addressAlreadyInUse
        case EADDRNOTAVAIL: self = .cannotAssignRequestedAddress

        /* ipc/network software -- operational errors */
        case ENETDOWN: self = .networkIsDown
        case ENETUNREACH: self = .networkIsUnreachable
        case ENETRESET: self = .networkDroppedConnectionOnReset
        case ECONNABORTED: self = .softwareCausedConnectionAbort
        case ECONNRESET: self = .connectionResetByPeer
        case ENOBUFS: self = .noBufferSpaceAvailable
        case EISCONN: self = .socketIsAlreadyConnected
        case ENOTCONN: self = .socketIsNotConnected

        case ESHUTDOWN: self = .cannotSendAfterSocketShutdown
        case ETOOMANYREFS: self = .tooManyReferences

        case ETIMEDOUT: self = .operationTimedOut
        case ECONNREFUSED: self = .connectionRefused

        case ELOOP: self = .tooManyLevelsOfSymbolicLinks
        case ENAMETOOLONG: self = .fileNameTooLong

        case EHOSTDOWN: self = .hostIsDown

        case EHOSTUNREACH: self = .noRouteToHost
        case ENOTEMPTY: self = .directoryNotEmpty

        /* quotas & mush */
        case EUSERS: self = .tooManyUsers

        case EDQUOT: self = .diskQuotaExceeded

        /* Network File System */
        case ESTALE: self = .staleFileHandle
        case EREMOTE: self = .objectIsRemote

        case ENOLCK: self = .noLocksAvailable
        case ENOSYS: self = .functionNotImplemented

        case EOVERFLOW: self = .valueTooLargeForDefinedDataType

        case ECANCELED: self = .operationCanceled

        case EIDRM: self = .identifierRemoved
        case ENOMSG: self = .noMessageOfDesiredType
        case EILSEQ: self = .illegalByteSequence

        case EBADMSG: self = .badMessage
        case EMULTIHOP: self = .multihopAttempted
        case ENODATA: self = .noDataAvailable
        case ENOLINK: self = .linkHasBeenSevered
        case ENOSR: self = .outOfStreamsResources
        case ENOSTR: self = .deviceNotAStream
        case EPROTO: self = .protocolError
        case ETIME: self = .timerExpired

        case ENOTRECOVERABLE: self = .stateNotRecoverable
        case EOWNERDEAD: self = .previousOwnerDied
        default: self = .other(errorNumber: errorNumber)
        }
    }
}

extension SystemError {
    public var errorNumber: Int32 {
        switch self {
        case .success: return 0
            
        case .operationNotPermitted: return EPERM
        case .noSuchFileOrDirectory: return ENOENT
        case .noSuchProcess: return ESRCH
        case .interruptedSystemCall: return EINTR
        case .inputOutputError: return EIO
        case .deviceNotConfigured: return ENXIO
        case .argumentListTooLong: return E2BIG
        case .executableFormatError: return ENOEXEC
        case .badFileDescriptor: return EBADF
        case .noChildProcesses: return ECHILD
        case .resourceDeadlockAvoided: return EDEADLK
        case .cannotAllocateMemory: return ENOMEM
        case .permissionDenied: return EACCES
        case .badAddress: return EFAULT

        case .blockDeviceRequired: return ENOTBLK

        case .deviceOrResourceBusy: return EBUSY
        case .fileExists: return EEXIST
        case .crossDeviceLink: return EXDEV
        case .operationNotSupportedByDevice: return ENODEV
        case .notADirectory: return ENOTDIR
        case .isADirectory: return EISDIR
        case .invalidArgument: return EINVAL
        case .tooManyOpenFilesInSystem: return ENFILE
        case .tooManyOpenFiles: return EMFILE
        case .inappropriateInputOutputControlForDevice: return ENOTTY
        case .textFileBusy: return ETXTBSY
        case .fileTooLarge: return EFBIG
        case .noSpaceLeftOnDevice: return ENOSPC
        case .illegalSeek: return ESPIPE
        case .readOnlyFileSystem: return EROFS
        case .tooManyLinks: return EMLINK
        case .brokenPipe: return EPIPE

        /* math software */
        case .numericalArgumentOutOfDomain: return EDOM
        case .resultTooLarge: return ERANGE

        /* non-blocking and interrupt i/o */
        case .resourceTemporarilyUnavailable: return EAGAIN
        case .operationWouldBlock: return EWOULDBLOCK
        case .operationNowInProgress: return EINPROGRESS
        case .operationAlreadyInProgress: return EALREADY

        /* ipc/network software -- argument errors */
        case .socketOperationOnNonSocket: return ENOTSOCK
        case .destinationAddressRequired: return EDESTADDRREQ
        case .messageTooLong: return EMSGSIZE
        case .protocolWrongTypeForSocket: return EPROTOTYPE
        case .protocolNotAvailable: return ENOPROTOOPT
        case .protocolNotSupported: return EPROTONOSUPPORT

        case .socketTypeNotSupported: return ESOCKTNOSUPPORT

        case .operationNotSupported: return ENOTSUP

        case .protocolFamilyNotSupported: return EPFNOSUPPORT

        case .addressFamilyNotSupportedByProtocolFamily: return EAFNOSUPPORT
        case .addressAlreadyInUse: return EADDRINUSE
        case .cannotAssignRequestedAddress: return EADDRNOTAVAIL

        /* ipc/network software -- operational errors */
        case .networkIsDown: return ENETDOWN
        case .networkIsUnreachable: return ENETUNREACH
        case .networkDroppedConnectionOnReset: return ENETRESET
        case .softwareCausedConnectionAbort: return ECONNABORTED
        case .connectionResetByPeer: return ECONNRESET
        case .noBufferSpaceAvailable: return ENOBUFS
        case .socketIsAlreadyConnected: return EISCONN
        case .socketIsNotConnected: return ENOTCONN

        case .cannotSendAfterSocketShutdown: return ESHUTDOWN
        case .tooManyReferences: return ETOOMANYREFS

        case .operationTimedOut: return ETIMEDOUT
        case .connectionRefused: return ECONNREFUSED

        case .tooManyLevelsOfSymbolicLinks: return ELOOP
        case .fileNameTooLong: return ENAMETOOLONG

        case .hostIsDown: return EHOSTDOWN

        case .noRouteToHost: return EHOSTUNREACH
        case .directoryNotEmpty: return ENOTEMPTY

        /* quotas & mush */
        case .tooManyUsers: return EUSERS

        case .diskQuotaExceeded: return EDQUOT

        /* Network File System */
        case .staleFileHandle: return ESTALE
        case .objectIsRemote: return EREMOTE

        case .noLocksAvailable: return ENOLCK
        case .functionNotImplemented: return ENOSYS

        case .valueTooLargeForDefinedDataType: return EOVERFLOW

        case .operationCanceled: return ECANCELED

        case .identifierRemoved: return EIDRM
        case .noMessageOfDesiredType: return ENOMSG
        case .illegalByteSequence: return EILSEQ

        case .badMessage: return EBADMSG
        case .multihopAttempted: return EMULTIHOP
        case .noDataAvailable: return ENODATA
        case .linkHasBeenSevered: return ENOLINK
        case .outOfStreamsResources: return ENOSR
        case .deviceNotAStream: return ENOSTR
        case .protocolError: return EPROTO
        case .timerExpired: return ETIME

        case .stateNotRecoverable: return ENOTRECOVERABLE
        case .previousOwnerDied: return EOWNERDEAD

        case .other(let errorNumber): return errorNumber
        }
    }
}

extension SystemError : Equatable {}

public func == (lhs: SystemError, rhs: SystemError) -> Bool {
    return lhs.errorNumber == rhs.errorNumber
}

extension SystemError {
    public static func description(for errorNumber: Int32) -> String {
        return String(cString: strerror(errorNumber))
    }
}

extension SystemError : CustomStringConvertible {
    public var description: String {
        return SystemError.description(for: errorNumber)
    }
}

extension SystemError {
    public static var lastOperationError: SystemError {
        return SystemError(errorNumber: errno)
    }
}
