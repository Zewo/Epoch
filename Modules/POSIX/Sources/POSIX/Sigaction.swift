//
//  Sigaction.swift
//  Zewo
//
//  Created by Ronaldo Faria Lima on 12/01/17.
//
//

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CPOSIX

/// This enumaration declares all signals according to header file signal.h,
/// exposing them to swift
/// - seealso: sys/signal.h on Darwin platforms
///
/// - hup: Hangup
/// - int: Interrupt
/// - quit: Quit
/// - ill: Illegal instruction
/// - trap: Trace trap
/// - abrt: Abort
/// - poll: Pollable event
/// - fpe: Floating point exception
/// - kill: Process kill. Cannot be caught or ignored
/// - bus: Bus error
/// - segv: Segmentation violation
/// - sys: Bad argument to system call
/// - pipe: Write to a pipe with no one to read it
/// - alrm: Alarm clock
/// - term: Software terminal signal from kill
/// - urg: Urgent condition on I/O Channel
/// - stop: Sendable STOP signal not from TTY. Cannot be caught or ignored
/// - stp: Stop signal from TTY
/// - cont: Continue a stopped process
/// - chld: To parent, on child stop or exit
/// - ttin: To readers pgrp upon background tty read
/// - ttou: Like TTIN for output
/// - io: Input/Output possible signal
/// - xcpu: Exceeded CPU time limit
/// - xfsz: Exceeded fil size limit
/// - vtalrm: Virtual time alarm
/// - prof: Profiling time alarm
/// - winch: Window size changes
/// - info: Information request
/// - usr1: User-defined signal 1
/// - usr2: User-defined signal 2
/// - unknown: Unknown or unsupported signal
public enum SignalType : Int32 {
    case hup    = 1
    case int    = 2
    case quit   = 3
    case ill    = 4
    case trap   = 5
    case abrt   = 6
    case poll   = 7
    case fpe    = 8
    case kill   = 9
    case bus    = 10
    case segv   = 11
    case sys    = 12
    case pipe   = 13
    case alrm   = 14
    case term   = 15
    case urg    = 16
    case stop   = 17
    case stp    = 18
    case cont   = 19
    case chld   = 20
    case ttin   = 21
    case ttou   = 22
    case io     = 23
    case xcpu   = 24
    case xfsz   = 25
    case vtalrm = 26
    case prof   = 27
    case winch  = 28
    case info   = 29
    case usr1   = 30
    case usr2   = 31
    case unknown
    
    /// Initializer that avoids failable initialization. If the raw value is not recognized,
    /// uses .unknown as default value.
    ///
    /// - Parameter rawValue: Signal number
    public init(rawValue: Int32) {
        switch rawValue {
        case  1: self = .hup   case  2: self = .int     case  3: self = .quit  case  4: self = .ill
        case  5: self = .trap  case  6: self = .abrt    case  7: self = .poll  case  8: self = .fpe
        case  9: self = .kill  case 10: self = .bus     case 11: self = .segv  case 12: self = .sys
        case 13: self = .pipe  case 14: self = .alrm    case 15: self = .term  case 16: self = .urg
        case 17: self = .stop  case 18: self = .stp     case 19: self = .cont  case 20: self = .chld
        case 21: self = .ttin  case 22: self = .ttou    case 23: self = .io    case 24: self = .xcpu
        case 25: self = .xfsz  case 26: self = .vtalrm  case 27: self = .prof  case 28: self = .winch
        case 29: self = .info  case 30: self = .usr1    case 31: self = .usr2
        default: self = .unknown
        }
    }
}

/// Defines the kind of action to take when a signal is delivered
///
/// - ignore: Ignores the signal. If the signal gets delivered to the process,
/// it will have no effect.
/// - useDefault: Uses default handler for the signal being delivered to the
/// process.
/// - handle: Handles the signal delivery by calling a custom handler.
public enum SignalAction : Int32 {
    case ignore = 0
    case useDefault = 1
    case handle = 2
}

/// Type for signal handlers
///
/// - parameters:
///     SignalType: The type of raised signal. Identifies the signal for the handler
public typealias SignalHandler = (SignalType)->Void

/// Errors raised by Signal handler routines
///
/// - cannotHandle(signal:): thrown when the signal cannot be handled or ignored
/// - invalidTrapCombination: attempted to use an invalid combination for trapping signals
/// - invalidSignal: attempted to use an invalid signal
public enum SignalError: Error, Hashable {
    case cannotHandle(signal: SignalType)
    case invalidTrapCombination
    case invalidSignal

    public var hashValue: Int {
        switch self {
        case .cannotHandle(let signal):
            return signal.hashValue
        case .invalidTrapCombination:
            return 0xcafe
        case .invalidSignal:
            return 0x51541
        }
    }
    
    public static func ==(a: SignalError, b: SignalError) -> Bool {
        return a.hashValue == b.hashValue
    }
}

/// This class encapsulates all necessary functionality to handle signals sent
/// by a given operating system.
///
/// - Throws
///    - cannotHandle(signal:): signal cannot be handled or ignored
///    - invalidTrapCombination: attempted an invalid combination to trap
///    signals.
///
/// - remarks:
/// By design, this struct have only static methods. It was done that way
/// because of the nature of signals: they are delivered to the process, not to
/// a given scope within the process. Also, sigaction system call is global to
/// the process. Therefore, it means that Signal structure must be a
/// singleton. Since sigaction need a method from a static structure, it was
/// preferred to use only static methods and properties instead of sticking with
/// a normal singleton implementation.
public struct Signal {
    /// Table of signal handlers
    static var signalTable: [SignalType:SignalHandler] = [:]
    
    /// Sets a trap for a given signal, providing an action and a handler.
    ///
    /// - parameters:
    ///     - signal: Signal to add treatment to
    ///     - action: What to do when the signal is delivered
    ///     - handler: A closure that will be called when the signal is delivered.
    ///
    /// - remarks:
    /// If the action is .ignore or .useDefault, the handler parameter will be
    /// ignored. The handler will be used only if the action is .handle.
    ///
    /// Signals stop and kill cannot be ignored or trapped. Trying to do so will
    /// raise an exception.
    public static func trap(signal: SignalType, action: SignalAction, handler: SignalHandler? = nil) throws {
        guard signal != .unknown && signal != .stop && signal != .kill else {
            throw SignalError.cannotHandle(signal: signal)
        }
        guard action != .handle || handler != nil else {
            throw SignalError.invalidTrapCombination
        }
        if action == .handle {
            signalTable[signal] = handler!
        }
        CPOSIXInstallSignalHandler(signal.rawValue, action.rawValue) { (signal) in
            Signal.handleSignal(signal: signal)
        }
    }
    
    /// Convenience method to add several signal handlers at once.
    ///
    /// - Parameters:
    ///   - signals: List of signals to handle
    ///   - handler: Handler that will handle the signals
    /// - Throws: SignalError.cannotHandle if signals contains .unknown, .stop or .kill.
    ///
    /// - Remarks:
    /// This method will schedule the same signal handler for all provided signals. So, it is the responsibility of 
    /// the signal handler to select the proper behavior for each received signal.
    public static func trap(for signals: SignalType..., handler: @escaping SignalHandler) throws {
        for signal in signals {
            guard signal != .unknown && signal != .stop && signal != .kill else {
                throw SignalError.cannotHandle(signal: signal)
            }
            signalTable[signal] = handler
            CPOSIXInstallSignalHandler(signal.rawValue, SignalAction.handle.rawValue) { (signal) in
                Signal.handleSignal(signal: signal)
            }
        }
    }
    
    /// Convenience method. Use default signal actions for the provided list of signals.
    ///
    /// - Parameter signals: List of signals to use default signal handling
    /// - Throws: SignalError.cannotHandle if signals contains .unknown, .stop or .kill.
    public static func useDefault(for signals: SignalType...) throws {
        for signal in signals {
            signalTable.removeValue(forKey: signal)
            try trap(signal: signal, action: .useDefault)
        }
    }
    
    /// Convenience method. Ignore the provided list of signals
    ///
    /// - Parameter signals: List of signals to ignore
    /// - Throws: SignalError.cannotHandle if signals contains .unknown, .stop or .kill.
    public static func ignore(these signals: SignalType...) throws {
        for signal in signals {
            signalTable.removeValue(forKey: signal)
            try trap(signal: signal, action: .ignore)
        }
    }

    /// Sends a signal to a given process
    ///
    /// - parameters:
    ///     - pid: The pid to send the signal to. Defaults to current process
    ///     - signal: What signal to send.
    ///
    /// - throws: SignalError.invalidSignal if provided signal is .unknown
    public static func killPid(pid: pid_t = getpid(), signal: SignalType) throws {
        guard signal != .unknown else {
            throw SignalError.invalidSignal
        }
        kill(pid, signal.rawValue)
    }
    
    /// Signal handler. Wraps a call to the proper signal handler, if available.
    ///
    /// - parameters:
    ///     - signal: Signal delivered to the process.
    static func handleSignal(signal: Int32) {
        let receivedSignal = SignalType(rawValue: signal)
        if let signalHandler = signalTable[receivedSignal] {
            signalHandler(receivedSignal)
        }
    }
}
