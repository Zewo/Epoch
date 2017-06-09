#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Core
import Venice

public enum Body {
    public typealias Write = (Writable) throws -> Void
   
    case readable(Readable)
    case writable(Write)
}

extension Body {
    public static var empty: Body {
        return .readable(ReadableBuffer.empty)
    }
}

extension Body {
    public var isReadable: Bool {
        switch self {
        case .readable:
            return true
        default:
            return false
        }
    }
    
    public var readable: Readable? {
        switch self {
        case let .readable(readable):
            return readable
        default:
            return nil
        }
    }
    
    public func convertedToReadable() throws -> Readable {
        switch self {
        case let .readable(readable):
            return readable
        case let .writable(write):
            let writable = WritableBuffer()
            try write(writable)
            return ReadableBytes(writable.buffer)
        }
    }
    
    public var isWritable: Bool {
        switch self {
        case .writable: return true
        default: return false
        }
    }
    
    public var writable: Write? {
        switch self {
        case let .writable(write):
            return write
        default:
            return nil
        }
    }
}

fileprivate final class ReadableBytes : Readable {
    var buffer: ArraySlice<UInt8>
    
    fileprivate init(_ buffer: [UInt8]) {
        self.buffer = ArraySlice<UInt8>(buffer)
    }
    
    fileprivate func read(
        _ buffer: UnsafeMutableRawBufferPointer,
        deadline: Deadline
    ) throws -> UnsafeRawBufferPointer {
        guard !buffer.isEmpty && !self.buffer.isEmpty else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        let readCount = min(buffer.count, self.buffer.count)
        
        guard let destination = buffer.baseAddress else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        self.buffer.withUnsafeBytes {
            memcpy(destination, $0.baseAddress!, readCount)
            return
        }
        
        let read = buffer.prefix(readCount)
        self.buffer = self.buffer.suffix(from: readCount)
        return UnsafeRawBufferPointer(read)
    }
}
