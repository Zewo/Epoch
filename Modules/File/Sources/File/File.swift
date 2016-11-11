#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

@_exported import Axis
import CLibvenice

public enum FileMode {
    case read
    case createWrite
    case truncateWrite
    case appendWrite
    case readWrite
    case createReadWrite
    case truncateReadWrite
    case appendReadWrite
}

extension FileMode {
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

public let standardInputStream: Stream = try! File(fileDescriptor: STDIN_FILENO)
public let standardOutputStream: Stream = try! File(fileDescriptor: STDOUT_FILENO)
public let standardErrorStream: Stream = try! File(fileDescriptor: STDERR_FILENO)

public final class File : Stream {
    fileprivate var file: mfile?
    public fileprivate(set) var closed = false
    public fileprivate(set) var path: String? = nil

    public func cursorPosition() throws -> Int {
        let position = Int(mill_mftell_(file))
        try ensureLastOperationSucceeded()
        return position
    }

    public func seek(cursorPosition: Int) throws -> Int {
        let position = Int(mill_mfseek_(file, off_t(cursorPosition)))
        try ensureLastOperationSucceeded()
        return position
    }

    public var length: Int {
        return Int(mill_mfsize_(self.file))
    }

    public var cursorIsAtEndOfFile: Bool {
        return mill_mfeof_(file) != 0
    }

    public lazy var fileExtension: String? = {
        guard let path = self.path else {
            return nil
        }

        guard let fileExtension = path.split(separator: ".").last else {
            return nil
        }

        if fileExtension.split(separator: "/").count > 1 {
            return nil
        }

        return fileExtension
    }()

    init(file: mfile) {
        self.file = file
    }

    public convenience init(fileDescriptor: FileDescriptor) throws {
        let file = mill_mfattach_(fileDescriptor)
        try ensureLastOperationSucceeded()
        self.init(file: file!)
    }

    public convenience init(path: String, mode: FileMode = .read) throws {
        let file = mill_mfopen_(path, mode.value, S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH)
        try ensureLastOperationSucceeded()
        self.init(file: file!)
        self.path = path
    }

    deinit {
        if let file = file, !closed {
            mill_mfclose_(file)
        }
    }
}

extension File {
    // TODO: Actually open the file here instead of init.
    public func open(deadline: Double) throws {}

    public func close() {
        if !closed {
            mill_mfclose_(file)
        }
        closed = true
    }
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>, deadline: Double) throws {
        guard !buffer.isEmpty else {
            return
        }
        
        try ensureFileIsOpen()
        
        let bytesWritten = mill_mfwrite_(file, buffer.baseAddress!, buffer.count, deadline.int64milliseconds)
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
        
        let bytesRead = mill_mfreadlh_(file, readPointer, 1, readBuffer.count, deadline.int64milliseconds)
        
        guard bytesRead > 0 else {
            try ensureLastOperationSucceeded()
            return UnsafeBufferPointer()
        }
        
        return UnsafeBufferPointer(start: readPointer, count: bytesRead)
    }

    public func readAll(bufferSize: Int = 2048, deadline: Double) throws -> Buffer {
        var buffer = Buffer()
        
        while true {
            let chunk = try self.read(upTo: bufferSize, deadline: deadline)
            
            if chunk.count == 0 || cursorIsAtEndOfFile {
                break
            }
            
            buffer.append(chunk)
        }
        
        return buffer
    }

    public func flush(deadline: Double) throws {
        try ensureFileIsOpen()
        mill_mfflush_(file, deadline.int64milliseconds)
        try ensureLastOperationSucceeded()
    }

    private func ensureFileIsOpen() throws {
        if closed {
            throw StreamError.closedStream
        }
    }
}

extension File {
    public static var workingDirectory: String {
        var buffer = [Int8](repeating: 0, count: Int(MAXNAMLEN))
        let workingDirectory = getcwd(&buffer, buffer.count)
        return String(cString: workingDirectory!)
    }

    public static func changeWorkingDirectory(path: String) throws {
        if chdir(path) == -1 {
            try ensureLastOperationSucceeded()
        }
    }

    public static func contentsOfDirectory(path: String) throws -> [String] {
        var contents: [String] = []

        guard let dir = opendir(path) else {
            try ensureLastOperationSucceeded()
            return []
        }

        defer {
            closedir(dir)
        }

        let excludeNames = [".", ".."]

        while let file = readdir(dir) {
            let entry: UnsafeMutablePointer<dirent> = file

            if let entryName = withUnsafeMutablePointer(to: &entry.pointee.d_name, { (ptr) -> String? in
                let entryPointer = unsafeBitCast(ptr, to: UnsafePointer<CChar>.self)
                return String(validatingUTF8: entryPointer)
            }) {
                if !excludeNames.contains(entryName) {
                    contents.append(entryName)
                }
            }
        }

        return contents
    }

    public static func fileExists(path: String) -> Bool {
        var s = stat()
        return lstat(path, &s) >= 0
    }

    public static func isDirectory(path: String) -> Bool {
        var s = stat()
        if lstat(path, &s) >= 0 {
            if (s.st_mode & S_IFMT) == S_IFLNK {
                if stat(path, &s) >= 0 {
                    return (s.st_mode & S_IFMT) == S_IFDIR
                }
                return false
            }
            return (s.st_mode & S_IFMT) == S_IFDIR
        }
        return false
    }

    public static func createDirectory(path: String, withIntermediateDirectories createIntermediates: Bool = false) throws {
        if createIntermediates {
            let (exists, directory) = (fileExists(path: path), isDirectory(path: path))
            if !exists {
                let parent = path.droppingLastPathComponent()

                if !fileExists(path: parent) {
                    try createDirectory(path: parent, withIntermediateDirectories: true)
                }
                if mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO) == -1 {
                    try ensureLastOperationSucceeded()
                }
            } else if directory {
                return
            } else {
                throw SystemError.fileExists
            }
        } else {
            if mkdir(path, S_IRWXU | S_IRWXG | S_IRWXO) == -1 {
                try ensureLastOperationSucceeded()
            }
        }
    }

    public static func removeFile(path: String) throws {
        if unlink(path) != 0 {
            try ensureLastOperationSucceeded()
        }
    }

    public static func removeDirectory(path: String) throws {
        if mill_mfremove_(path) != 0 {
            try ensureLastOperationSucceeded()
        }
    }
}
