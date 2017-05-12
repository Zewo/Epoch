#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import POSIX

let map: [Int32: SystemError] = [
    EPERM: .operationNotPermitted,
    ENOENT: .noSuchFileOrDirectory,
    ESRCH: .noSuchProcess,
    EINTR: .interruptedSystemCall,
    EIO: .inputOutputError,
    ENXIO: .deviceNotConfigured,
    E2BIG: .argumentListTooLong,
    ENOEXEC: .executableFormatError,
    EBADF: .badFileDescriptor,
    ECHILD: .noChildProcesses,
    EDEADLK: .resourceDeadlockAvoided,
    ENOMEM: .cannotAllocateMemory,
    EACCES: .permissionDenied,
    EFAULT: .badAddress,
    ENOTBLK: .blockDeviceRequired,
    EBUSY: .deviceOrResourceBusy,
    EEXIST: .fileExists,
    EXDEV: .crossDeviceLink,
    ENODEV: .operationNotSupportedByDevice,
    ENOTDIR: .notADirectory,
    EISDIR: .isADirectory,
    EINVAL: .invalidArgument,
    ENFILE: .tooManyOpenFilesInSystem,
    EMFILE: .tooManyOpenFiles,
    ENOTTY: .inappropriateInputOutputControlForDevice,
    ETXTBSY: .textFileBusy,
    EFBIG: .fileTooLarge,
    ENOSPC: .noSpaceLeftOnDevice,
    ESPIPE: .illegalSeek,
    EROFS: .readOnlyFileSystem,
    EMLINK: .tooManyLinks,
    EPIPE: .brokenPipe,
    EDOM: .numericalArgumentOutOfDomain,
    ERANGE: .resultTooLarge,

    // On Linux and OSX EAGAIN and EWOULDBLOCK are the same thing
    EAGAIN: .resourceTemporarilyUnavailable,
    //EWOULDBLOCK: .operationWouldBlock,

    EINPROGRESS: .operationNowInProgress,
    EALREADY: .operationAlreadyInProgress,
    ENOTSOCK: .socketOperationOnNonSocket,
    EDESTADDRREQ: .destinationAddressRequired,
    EMSGSIZE: .messageTooLong,
    EPROTOTYPE: .protocolWrongTypeForSocket,
    ENOPROTOOPT: .protocolNotAvailable,
    EPROTONOSUPPORT: .protocolNotSupported,
    ESOCKTNOSUPPORT: .socketTypeNotSupported,
    ENOTSUP: .operationNotSupported,
    EPFNOSUPPORT: .protocolFamilyNotSupported,
    EAFNOSUPPORT: .addressFamilyNotSupportedByProtocolFamily,
    EADDRINUSE: .addressAlreadyInUse,
    EADDRNOTAVAIL: .cannotAssignRequestedAddress,
    ENETDOWN: .networkIsDown,
    ENETUNREACH: .networkIsUnreachable,
    ENETRESET: .networkDroppedConnectionOnReset,
    ECONNABORTED: .softwareCausedConnectionAbort,
    ECONNRESET: .connectionResetByPeer,
    ENOBUFS: .noBufferSpaceAvailable,
    EISCONN: .socketIsAlreadyConnected,
    ENOTCONN: .socketIsNotConnected,
    ESHUTDOWN: .cannotSendAfterSocketShutdown,
    ETOOMANYREFS: .tooManyReferences,
    ETIMEDOUT: .operationTimedOut,
    ECONNREFUSED: .connectionRefused,
    ELOOP: .tooManyLevelsOfSymbolicLinks,
    ENAMETOOLONG: .fileNameTooLong,
    EHOSTDOWN: .hostIsDown,
    EHOSTUNREACH: .noRouteToHost,
    ENOTEMPTY: .directoryNotEmpty,
    EUSERS: .tooManyUsers,
    EDQUOT: .diskQuotaExceeded,
    ESTALE: .staleFileHandle,
    EREMOTE: .objectIsRemote,
    ENOLCK: .noLocksAvailable,
    ENOSYS: .functionNotImplemented,
    EOVERFLOW: .valueTooLargeForDefinedDataType,
    ECANCELED: .operationCanceled,
    EIDRM: .identifierRemoved,
    ENOMSG: .noMessageOfDesiredType,
    EILSEQ: .illegalByteSequence,
    EBADMSG: .badMessage,
    EMULTIHOP: .multihopAttempted,
    ENODATA: .noDataAvailable,
    ENOLINK: .linkHasBeenSevered,
    ENOSR: .outOfStreamsResources,
    ENOSTR: .deviceNotAStream,
    EPROTO: .protocolError,
    ETIME: .timerExpired,
    ENOTRECOVERABLE: .stateNotRecoverable,
    EOWNERDEAD: .previousOwnerDied,
    666: .other(errorNumber: 666)
]

public class POSIXTests : XCTestCase {
    func testCreation() {
        for (errorNumber, error) in map {
            XCTAssertEqual(SystemError(errorNumber: errorNumber), error)
        }
        
        XCTAssertEqual(SystemError(errorNumber: EWOULDBLOCK), .operationWouldBlock)
    }

    func testDescription() {
        for (errorNumber, error) in map {
            XCTAssertEqual(error.description, String(cString: strerror(errorNumber)))
        }
    }

    func testLastOperationError() throws {
        errno = 0
        XCTAssertEqual(SystemError.lastOperationError, .success)
        
        for (errorNumber, error) in map {
            errno = errorNumber
            XCTAssertEqual(SystemError.lastOperationError, error)
            do {
                throw SystemError.lastOperationError
            } catch let systemError as SystemError {
                XCTAssertEqual(systemError, error)
            } catch {
                XCTFail("Should throw SystemError")
            }
        }
    }
}

extension POSIXTests {
    public static var allTests: [(String, (POSIXTests) -> () throws -> Void)] {
        return [
            ("testCreation", testCreation),
            ("testDescription", testDescription),
            ("testLastOperationError", testLastOperationError),
        ]
    }
}
