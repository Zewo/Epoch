import Venice
import Foundation

public protocol UnsafeRawBufferPointerRepresentable {
    /// Invokes the given closure on the contents represented as a buffer.
    ///
    /// The `withUnsafeBytes(body:)` method ensures that the buffer's lifetime extends
    /// through the execution of `body`. The buffer argument to `body` is only
    /// valid for the lifetime of the closure. Do not escape it from the closure
    /// for later use.
    ///
    /// - Parameter body: A closure that takes a buffer as its sole argument.
    ///   If the closure has a return value, it is used as the return value of 
    ///   the `withUnsafeBytes(body:)` method.
    ///   The buffer argument is valid only for the duration of the closure's
    ///   execution.
    /// - Parameter buffer: A buffer representing the contents of the underlying type.
    /// - Returns: The return value of the `body` closure, if any.
    /// - Throws: Errors thrown from the `body` closure, if any.
    func withUnsafeBytes<ResultType>(
        body: (_ buffer: UnsafeRawBufferPointer) throws -> ResultType
    ) rethrows -> ResultType
}

extension String : UnsafeRawBufferPointerRepresentable {
    public func withUnsafeBytes<ResultType>(
        body: (_ buffer: UnsafeRawBufferPointer) throws -> ResultType
    ) rethrows -> ResultType {
        return try withCString { unsafePointer in
            let unsafeRawBufferPointer = UnsafeRawBufferPointer(
                start: UnsafeRawPointer(unsafePointer),
                count: utf8.count
            )
            
            return try body(unsafeRawBufferPointer)
        }
    }
}

extension Data : UnsafeRawBufferPointerRepresentable {
    public func withUnsafeBytes<ResultType>(
        body: (_ buffer: UnsafeRawBufferPointer) throws -> ResultType
    ) rethrows -> ResultType {
        return try withUnsafeBytes { (unsafePointer: UnsafePointer<UInt8>) in
            let unsafeRawBufferPointer = UnsafeRawBufferPointer(
                start: UnsafeRawPointer(unsafePointer),
                count: count
            )
            
            return try body(unsafeRawBufferPointer)
        }
    }
}

public protocol ReadableStream {
    func open(deadline: Deadline) throws
    func close() throws

    func read(
        into buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer
}

public protocol WritableStream {
    func open(deadline: Deadline) throws
    func close() throws

    func write(_ buffer: UnsafeRawBufferPointer, deadline: Deadline) throws
    func flush(deadline: Deadline) throws
}

extension WritableStream {
    public func write(_ buffer: UnsafeRawBufferPointerRepresentable, deadline: Deadline) throws {
        try buffer.withUnsafeBytes {
            try write($0, deadline: deadline)
        }
    }
}

public typealias DuplexStream = ReadableStream & WritableStream
