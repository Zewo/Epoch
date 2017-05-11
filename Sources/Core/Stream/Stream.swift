import Venice
import Foundation

public protocol UnsafeRawBufferPointerRepresentable {
    /// Access the buffer in the data.
    ///
    /// - warning: The buffer pointer argument should not be stored and used outside of the lifetime of the call to the closure.
    func withUnsafeBytes<ResultType>(
        _ body: (UnsafeRawBufferPointer) throws -> ResultType
    ) rethrows -> ResultType
}

extension String : UnsafeRawBufferPointerRepresentable {
    public func withUnsafeBytes<ResultType>(
        _ body: (UnsafeRawBufferPointer) throws -> ResultType
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
        _ body: (UnsafeRawBufferPointer) throws -> ResultType
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
    func close()

    func read(
        into buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer
}

public protocol WritableStream {
    func open(deadline: Deadline) throws
    func close()

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
