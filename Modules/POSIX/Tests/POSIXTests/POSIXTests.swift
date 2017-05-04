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
        XCTAssertNil(SystemError(errorNumber: 0))
        for (errorNumber, error) in map {
            guard let initializedError = SystemError(errorNumber: errorNumber) else {
                return XCTFail("Initializing with \(errorNumber) should not be nil")
            }
            XCTAssertEqual(initializedError, error)
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
        XCTAssertNil(SystemError.lastOperationError)
        try ensureLastOperationSucceeded()
        for (errorNumber, error) in map {
            errno = errorNumber
            XCTAssertEqual(SystemError.lastOperationError, error)
            do {
                try ensureLastOperationSucceeded()
            } catch let systemError as SystemError {
                XCTAssertEqual(systemError, error)
            } catch {
                XCTFail("Should throw SystemError")
            }
        }
    }
    
    func testSignalDelivery() throws {
        var signalHandled = false
        try Signal.trap(signal: .usr1, action: .handle) { signal in
            signalHandled = true
        }
        try Signal.killPid(signal: .usr1)
        XCTAssert(signalHandled, "Signal was not handled. Failed!")
    }
    
    func testSignalTypeEnum() {
        for sig in 1...31 {
            let signal = SignalType(rawValue: Int32(sig))
            XCTAssertEqual(signal.rawValue, Int32(sig), "Invalid signal type")
        }
    }
    
    func testSignalWrongTrapCombinations() throws {
        do {
            try Signal.trap(signal: .kill, action: .ignore)
        } catch SignalError.cannotHandle(signal: let signalType) {
            XCTAssertEqual(signalType, .kill, "Invalid raised exception")
        }
        do {
            try Signal.trap(signal: .usr1, action: .handle)
        } catch SignalError.invalidTrapCombination {
            // Ok!
        }
    }
    
    func testSignalSendInvalidSignal() throws {
        do {
            try Signal.killPid(signal: .unknown)
        } catch SignalError.invalidSignal {
            // Ok!
        }
    }
    
    func testSignalErrorHashes() {
        let a = SignalError.cannotHandle(signal: .kill)
        let b = SignalError.cannotHandle(signal: .kill)
        let c = SignalError.cannotHandle(signal: .stop)
        XCTAssertEqual(a, b, "Should be equal")
        XCTAssertNotEqual(a, c, "Should not be equal")
        XCTAssertNotEqual(b, c, "Should not be equal")
        let d = SignalError.invalidTrapCombination
        let e = SignalError.invalidTrapCombination
        let f = SignalError.invalidSignal
        XCTAssertEqual(d, e, "Should be equal")
        XCTAssertNotEqual(d, f, "Should not be equal")
        XCTAssertNotEqual(e, f, "Should not be equal")
    }
    
    func testSignalHandlingFromClass() {
        let signalHandler = SignalHandlerClass()
        do {
            try Signal.trap(signal: .usr1, action: .handle, handler: signalHandler.handleSignal(signal:))
            try Signal.killPid(signal: .usr1)
        } catch {
            XCTFail("Failed to trap/kill")
        }
        XCTAssertTrue(signalHandler.signalHandled, "Signal not handled")
    }
    
    func testSignalTrapMultiple() {
        var num = 0
        do {
            try Signal.trap(for: .usr1, .usr2) { (signal) in
                num += 1
            }
            try Signal.killPid(signal: .usr1)
            try Signal.killPid(signal: .usr2)
        } catch {
            XCTFail("Raised an unexpected exception")
        }
        XCTAssertEqual(num, 2, "Failed to catch signals")
    }
    
    func testSignalIgnoreMultiple() {
        do {
            try Signal.ignore(these: .usr1, .usr2)
            try Signal.killPid(signal: .usr1)
            try Signal.killPid(signal: .usr2)
        } catch {
            XCTFail("Raised an unexpected exception")
        }
    }
    
    func testSignalDefaultMultiple() {
        do {
            try Signal.trap(for: .chld, .cont) { (signal) in
                XCTFail("Handler cannot be called!")
            }
            try Signal.useDefault(for: .chld, .cont)
            try Signal.killPid(signal: .chld)
        } catch {
            XCTFail("Raised an unexpected exception")
        }
    }
    
    func testSignalFailingTrapList() {
        var raised = false
        do {
            try Signal.trap(for: .cont, .chld, .kill, .unknown, .stop) { (signal) in
                print("Trapped!")
            }
        } catch {
            raised = true
        }
        XCTAssertTrue(raised, "Expected exception")
    }
    
    func testSignalFailingIgnoreList() {
        var raised = false
        do {
            try Signal.ignore(these: .cont, .chld, .kill, .unknown, .stop)
        } catch {
            raised = true
        }
        XCTAssertTrue(raised, "Expected exception")
    }
    
    func testSignalFailingDefaultList() {
        var raised = false
        do {
            try Signal.useDefault(for: .cont, .chld, .kill, .unknown, .stop)
        } catch {
            raised = true
        }
        XCTAssertTrue(raised, "Expected exception")
    }
}

extension POSIXTests {
    public static var allTests: [(String, (POSIXTests) -> () throws -> Void)] {
        return [
            ("testCreation", testCreation),
            ("testDescription", testDescription),
            ("testLastOperationError", testLastOperationError),
            ("testSignalDelivery", testSignalDelivery),
            ("testSignalTypeEnum", testSignalTypeEnum),
            ("testSignalWrongTrapCombinations", testSignalWrongTrapCombinations),
            ("testSignalSendInvalidSignal", testSignalSendInvalidSignal),
            ("testSignalErrorHashes", testSignalErrorHashes),
            ("testSignalHandlingFromClass", testSignalHandlingFromClass),
            ("testSignalTrapMultiple", testSignalTrapMultiple),
            ("testSignalIgnoreMultiple", testSignalIgnoreMultiple),
            ("testSignalDefaultMultiple", testSignalDefaultMultiple),
        ]
    }
}

class SignalHandlerClass {
    var signalHandled = false
    
    func handleSignal(signal: SignalType) {
            signalHandled = true
    }
}
