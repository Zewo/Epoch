#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

@_exported import Axis
import CLibvenice

public let standardInputStream: Stream = try! FileDescriptorStream(fileDescriptor: STDIN_FILENO)
public let standardOutputStream: Stream = try! FileDescriptorStream(fileDescriptor: STDOUT_FILENO)
public let standardErrorStream: Stream = try! FileDescriptorStream(fileDescriptor: STDERR_FILENO)

public final class FileDescriptorStream : Stream {
    private var file: mfile
    public fileprivate(set) var closed = false

    public init(fileDescriptor: FileDescriptor) throws {
        file = fileattach(fileDescriptor)
        try ensureLastOperationSucceeded()
    }

    public init(path: String, mode: File.Mode = .read) throws {
        file = fileopen(path, mode.value, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
        try ensureLastOperationSucceeded()
    }

    deinit {
        if !closed {
            fileclose(file)
        }
    }

    public func open(deadline: Double) throws {}

    public func close() {
        if !closed {
            fileclose(file)
        }
        closed = true
    }

    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        guard !buffer.isEmpty else {
            return
        }

        try ensureFileIsOpen()

        let bytesWritten = filewrite(file, buffer.baseAddress!, buffer.count, deadline.int64milliseconds)
        guard bytesWritten == buffer.count else {
            try ensureLastOperationSucceeded()
            throw SystemError.other(errorNumber: -1)
        }
    }

    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        guard let readPointer = readBuffer.baseAddress else {
            return UnsafeBufferPointer()
        }

        try ensureFileIsOpen()

        let bytesRead = filereadlh(file, readPointer, 1, readBuffer.count, deadline.int64milliseconds)

        guard bytesRead > 0 else {
            try ensureLastOperationSucceeded()
            return UnsafeBufferPointer()
        }

        return UnsafeBufferPointer(start: readPointer, count: bytesRead)
    }

    public func flush(deadline: Double) throws {
        try ensureFileIsOpen()
        fileflush(file, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
    }

    private func ensureFileIsOpen() throws {
        if closed {
            throw StreamError.closedStream
        }
    }
}
