#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

@_exported import Axis
import CLibvenice
import Dispatch
import class Foundation.FileManager

public final class File : Stream {
    public enum Mode {
        case read
        case createWrite
        case truncateWrite
        case appendWrite
        case readWrite
        case createReadWrite
        case truncateReadWrite
        case appendReadWrite
    }

    private let io: DispatchIO
    private let path: String
    private let fileDescriptor: FileDescriptor
    private let semaphore = try! Semaphore()
    private let queue = DispatchQueue.global()
    public private(set) var closed = false

    public init(path: String, mode: Mode = .read) throws {
        let fileDescriptor = try openFile(path: path, mode: mode)
        self.path = path
        self.fileDescriptor = fileDescriptor
        self.io = DispatchIO(type: .stream, fileDescriptor: fileDescriptor, queue: queue) { _ in
            closeFile(fileDescriptor: fileDescriptor)
        }
    }

    deinit {
        close()
    }

    public func open(deadline: Double) throws {}

    public func close() {
        if !closed {
            io.close()
            closed = true
        }
    }

    public func read(into readBuffer: UnsafeMutableBufferPointer<Byte>, deadline: Double) throws -> UnsafeBufferPointer<Byte> {
        try ensureFileIsOpen()

        guard var readPointer = readBuffer.baseAddress else {
            return UnsafeBufferPointer()
        }

        var resultError: Error?
        var bytesRead = 0

        io.read(offset: 0, length: readBuffer.count, queue: queue) { (done, data, errorNumber) in
            if let error = SystemError(errorNumber: errorNumber) {
                resultError = error
            }

            if let data = data, !data.isEmpty {
                data.copyBytes(to: readPointer, count: data.count)
                readPointer += data.count
                bytesRead += data.count
            }

            if done {
                self.semaphore.signal()
            }
        }

        try semaphore.wait(deadline: deadline)

        guard resultError == nil else {
            throw resultError!
        }

        return UnsafeBufferPointer(start: readBuffer.baseAddress, count: bytesRead)
    }

    public func write(_ writeBuffer: UnsafeBufferPointer<Byte>, deadline: Double) throws {
        try ensureFileIsOpen()

        guard !writeBuffer.isEmpty else {
            return
        }

        var resultError: Error?
        let data = DispatchData(bytesNoCopy: writeBuffer, deallocator: .custom(nil, {}))

        io.write(offset: 0, data: data, queue: queue) { (done, data, errorNumber) in
            if let error = SystemError(errorNumber: errorNumber) {
                resultError = error
            }

            if done {
                self.semaphore.signal()
            }
        }

        try semaphore.wait(deadline: deadline)

        guard resultError == nil else {
            throw resultError!
        }
    }

    public func flush(deadline: Double) throws {
        try ensureFileIsOpen()
    }

    private func ensureFileIsOpen() throws {
        if closed {
            throw StreamError.closedStream
        }
    }

    public lazy var fileExtension: String? = {
        guard let fileExtension = self.path.split(separator: ".").last else {
            return nil
        }

        if fileExtension.split(separator: "/").count > 1 {
            return nil
        }

        return fileExtension
    }()

    public func cursorPosition() throws -> Int {
        let position = lseek(fileDescriptor, 0, SEEK_CUR)

        guard position != -1 else {
            throw SystemError.lastOperationError!
        }

        return Int(position)
    }

    public func seek(cursorPosition: Int) throws -> Int {
        let position = lseek(fileDescriptor, off_t(cursorPosition), SEEK_SET)

        guard position != -1 else {
            throw SystemError.lastOperationError!
        }

        return Int(position)
    }

    public func size() throws -> Int {
        let currentPosition = lseek(fileDescriptor, 0, SEEK_CUR)

        guard currentPosition != -1 else {
            throw SystemError.lastOperationError!
        }

        let size = lseek(fileDescriptor, 0, SEEK_END)

        guard size != -1 else {
            throw SystemError.lastOperationError!
        }

        let result = lseek(fileDescriptor, currentPosition, SEEK_SET)

        guard result != -1 else {
            throw SystemError.lastOperationError!
        }

        return Int(size)
    }
}

extension File.Mode {
    var value: Int32 {
        switch self {
        case .read: return O_RDONLY
        case .createWrite: return (O_WRONLY | O_CREAT | O_EXCL)
        case .truncateWrite: return (O_WRONLY | O_CREAT | O_TRUNC)
        case .appendWrite: return (O_WRONLY | O_CREAT | O_APPEND)
        case .readWrite: return (O_RDWR)
        case .createReadWrite: return (O_RDWR | O_CREAT | O_EXCL)
        case .truncateReadWrite: return (O_RDWR | O_CREAT | O_TRUNC)
        case .appendReadWrite: return (O_RDWR | O_CREAT | O_APPEND)
        }
    }
}

fileprivate func openFile(path: String, mode: File.Mode) throws -> FileDescriptor {
    let fileDescriptor = path.withCString {
        open($0, mode.value, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
    }

    guard fileDescriptor != -1 else {
        throw SystemError.lastOperationError!
    }

    return fileDescriptor
}

fileprivate func closeFile(fileDescriptor: FileDescriptor) {
    close(fileDescriptor)
}

extension File {
    public static var currentDirectoryPath: String {
        return FileManager.default.currentDirectoryPath
    }

    public static func changeCurrentDirectory(path: String) throws {
        guard chdir(path) == 0 else {
            throw SystemError.lastOperationError!
        }
    }

    public static func contentsOfDirectory(atPath path: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
    }

    public static func fileExists(atPath path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    public static func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }

    public static func createDirectory(atPath path: String, withIntermediateDirectories createIntermediates: Bool = false, attributes: [String: Any] = [:]) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }

    public static func removeItem(atPath path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
}











public class Semaphore {
    private var reader: unixsock?
    private let writerFileDescriptor: FileDescriptor

    public init() throws {
        var writer: unixsock? = nil
        unixpair(&reader, &writer)
        try ensureLastOperationSucceeded()

        writerFileDescriptor = unixdetach(writer)
        try ensureLastOperationSucceeded()

        let flags = fcntl(writerFileDescriptor, F_GETFL)

        guard flags != -1 else {
            throw SystemError.lastOperationError!
        }

        guard fcntl(writerFileDescriptor, F_SETFL, flags & ~O_NONBLOCK) != -1 else {
            throw SystemError.lastOperationError!
        }
    }

    deinit {
        unixclose(reader)
        close(writerFileDescriptor)
    }

    public func signal() {
        var byte: Byte = 0
        guard send(writerFileDescriptor, &byte, 1, 0) != -1 else {
            fatalError(SystemError.lastOperationError!.description)
        }
    }

    public func wait(deadline: Double) throws {
        var byte: Byte = 0
        unixrecv(reader, &byte, 1, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
    }
}
