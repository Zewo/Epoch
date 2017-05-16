import Core
import Venice

public enum ResponseSerializerError : Error {
    case invalidContentLength
}

public final class ResponseSerializer {
    private let stream: WritableStream
    private let bufferSize: Int
    private let buffer: UnsafeMutableRawBufferPointer

    public init(stream: WritableStream, bufferSize: Int) {
        self.stream = stream
        self.bufferSize = bufferSize
        self.buffer = UnsafeMutableRawBufferPointer.allocate(count: bufferSize)
    }
    
    deinit {
        buffer.deallocate()
    }

    public func serialize(_ response: Response, deadline: Deadline) throws -> Bool {
        try writeHeaders(for: response, deadline: deadline)
        
        if let contentLength = response.contentLength {
            try writeBody(for: response, contentLength: contentLength, deadline: deadline)
            return true
        }
        
        if response.isChunkEncoded {
            try writeChunkEncodedBody(for: response, deadline: deadline)
            return true
        }
        
        try write(to: stream, body: response.body, deadline: deadline)
        return false
    }
    
    @inline(__always)
    private func writeHeaders(for response: Response, deadline: Deadline) throws {
        var header = response.version.description
        
        header += " "
        header += response.status.description
        header += "\r\n"
        
        for (name, value) in response.headers.headers {
            header += name.string
            header += ": "
            header += value
            header += "\r\n"
        }
        
        for cookie in response.cookieHeaders {
            header += "Set-Cookie: "
            header += cookie
            header += "\r\n"
        }
        
        header += "\r\n"
        
        try stream.write(header, deadline: deadline)
    }
    
    @inline(__always)
    private func writeBody(for response: Response, contentLength: Int, deadline: Deadline) throws {
        if contentLength < 0 {
            throw ResponseSerializerError.invalidContentLength
        }
        
        let bodyStream = ResponseBodyStream(stream, mode: .contentLength(contentLength))
        try write(to: bodyStream, body: response.body, deadline: deadline)
        
        if bodyStream.bytesRemaining > 0 {
            throw ResponseSerializerError.invalidContentLength
        }
    }
    
    @inline(__always)
    private func writeChunkEncodedBody(for response: Response, deadline: Deadline) throws {
        let bodyStream = ResponseBodyStream(stream, mode: .chunkedEncoding)
        try write(to: bodyStream, body: response.body, deadline: deadline)
        try stream.write("0\r\n\r\n", deadline: deadline)
    }
    
    @inline(__always)
    private func write(to writableStream: WritableStream, body: Body, deadline: Deadline) throws {
        switch body {
        case let .readable(readableStream):
            while true {
                let readBuffer = try readableStream.read(buffer, deadline: deadline)
                
                guard !readBuffer.isEmpty else {
                    break
                }
                
                try writableStream.write(readBuffer, deadline: deadline)
            }
        case let .writable(write):
            try write(writableStream)
        }
    }
}
