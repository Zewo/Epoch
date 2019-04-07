import Core
import Venice

// TODO: Make CustomStringConvertible
public enum SerializerError : Error {
    case invalidContentLength
    case writeExceedsContentLength
    case noContentLengthOrChunkedEncodingHeaders
}

internal class Serializer {
    final class BodyStream : Writable {
        enum Mode {
            case contentLength(Int)
            case chunkedEncoding
        }
        
        var bytesRemaining = 0
        
        private let stream: Writable
        private let mode: Mode
        
        init(_ stream: Writable, mode: Mode) {
            self.stream = stream
            self.mode = mode
            
            if case let .contentLength(contentLength) = mode {
                bytesRemaining = contentLength
            }
        }
        
        func write(_ buffer: UnsafeRawBufferPointer, deadline: Deadline) throws {
            guard !buffer.isEmpty else {
                return
            }
            
            switch mode {
            case .contentLength:
                if bytesRemaining - buffer.count < 0 {
                    throw SerializerError.writeExceedsContentLength
                }
                
                try stream.write(buffer, deadline: deadline)
                bytesRemaining -= buffer.count
            case .chunkedEncoding:
                let chunkLength = String(buffer.count, radix: 16) + "\r\n"
                try stream.write(chunkLength, deadline: deadline)
                try stream.write(buffer, deadline: deadline)
                try stream.write("\r\n", deadline: deadline)
            }
        }
    }
    
    internal let stream: Writable
    private let bufferSize: Int
    private let buffer: UnsafeMutableRawBufferPointer
    
    internal init(stream: Writable, bufferSize: Int) {
        self.stream = stream
        self.bufferSize = bufferSize
        self.buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: bufferSize, alignment: MemoryLayout<UInt8>.alignment)
    }
    
    deinit {
        buffer.deallocate()
    }
    
    internal func serializeHeaders(_ message: Message, deadline: Deadline) throws {
        var header = ""
        
        for (name, value) in message.headers {
            header += name.description
            header += ": "
            header += value
            header += "\r\n"
        }
        
        header += "\r\n"
        
        try stream.write(header, deadline: deadline)
    }
    
    internal func serializeBody(_ message: Message, deadline: Deadline) throws {
        if let contentLength = message.contentLength {
            try writeBody(message, contentLength: contentLength, deadline: deadline)
        }
        
        if message.isChunkEncoded {
            try writeChunkEncodedBody(message, deadline: deadline)
        }
    }
    
    @inline(__always)
    private func writeBody(_ message: Message, contentLength: Int, deadline: Deadline) throws {
        guard contentLength != 0 else {
            return
        }
        
        guard contentLength > 0 else {
            throw SerializerError.invalidContentLength
        }
        
        let bodyStream = BodyStream(stream, mode: .contentLength(contentLength))
        try write(to: bodyStream, body: message.body, deadline: deadline)
        
        if bodyStream.bytesRemaining > 0 {
            throw SerializerError.invalidContentLength
        }
    }
    
    @inline(__always)
    private func writeChunkEncodedBody(_ message: Message, deadline: Deadline) throws {
        let bodyStream = BodyStream(stream, mode: .chunkedEncoding)
        try write(to: bodyStream, body: message.body, deadline: deadline)
        try stream.write("0\r\n\r\n", deadline: deadline)
    }
    
    @inline(__always)
    private func write(to writable: Writable, body: Body, deadline: Deadline) throws {
        switch body {
        case let .readable(readable):
            while true {
                let read = try readable.read(buffer, deadline: deadline)
                
                guard !read.isEmpty else {
                    break
                }
                
                try writable.write(read, deadline: deadline)
            }
        case let .writable(write):
            try write(writable)
        }
    }
}
