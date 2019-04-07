import CHTTPParser
import Core
import Foundation
import Venice

public typealias ParserError = http_errno

extension ParserError : Error, CustomStringConvertible {
    public var description: String {
        return String(cString: http_errno_description(self))
    }
}

internal class Parser {
    final class BodyStream : Readable {
        var complete = false
        var bodyBuffer = UnsafeRawBufferPointer(start: nil, count: 0)
        
        private let parser: Parser
        
        public init(parser: Parser) {
            self.parser = parser
        }
        
        func read(
            _ buffer: UnsafeMutableRawBufferPointer,
            deadline: Deadline
        ) throws -> UnsafeRawBufferPointer {
            guard let baseAddress = buffer.baseAddress else {
                return UnsafeRawBufferPointer(start: nil, count: 0)
            }
            
            if bodyBuffer.isEmpty {
                guard !complete else {
                    return UnsafeRawBufferPointer(start: nil, count: 0)
                }
                
                try parser.read(deadline: deadline)
            }
            
            guard let bodyBaseAddress = bodyBuffer.baseAddress else {
                return UnsafeRawBufferPointer(start: nil, count: 0)
            }
            
            let bytesRead = min(bodyBuffer.count, buffer.count)
            memcpy(baseAddress, bodyBaseAddress, bytesRead)
            
            #if swift(>=3.2)
                bodyBuffer = UnsafeRawBufferPointer(rebasing: bodyBuffer.suffix(from: bytesRead))
            #else
                bodyBuffer = bodyBuffer.suffix(from: bytesRead)
            #endif
            
            return UnsafeRawBufferPointer(start: baseAddress, count: bytesRead)
        }
    }
    
    fileprivate enum State: Int {
        case ready = 1
        case messageBegin = 2
        case uri = 3
        case status = 4
        case headerField = 5
        case headerValue = 6
        case headersComplete = 7
        case body = 8
        case messageComplete = 9
    }
    
    internal class Context {
        var uri: URI?
        var status: Response.Status? = nil
        var headers: Headers = [:]
        var currentHeaderField: Headers.Field?
        
        weak var bodyStream: BodyStream?
        
        func addValueForCurrentHeaderField(_ value: String) {
            guard let key = currentHeaderField else {
                return
            }
            
            if let existing = headers[key] {
                headers[key] = existing + ", " + value
            } else {
                headers[key] = value
            }
        }
    }
    
    private let stream: Readable
    private let bufferSize: Int
    private let buffer: UnsafeMutableRawBufferPointer
    
    internal var parser: http_parser
    private var parserSettings: http_parser_settings
    
    private var state: State = .ready
    private var context = Context()
    private var bytes: [UInt8] = []
    
    public init(stream: Readable, bufferSize: Int = 2048, type: http_parser_type) {
        self.stream = stream
        self.bufferSize = bufferSize
        self.buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: bufferSize, alignment: MemoryLayout<UInt8>.alignment)
        
        var parser = http_parser()
        
        http_parser_init(&parser, type)
        
        var parserSettings = http_parser_settings()
        http_parser_settings_init(&parserSettings)
        
        parserSettings.on_message_begin = http_parser_on_message_begin
        parserSettings.on_url = http_parser_on_url
        parserSettings.on_status = http_parser_on_status
        parserSettings.on_header_field = http_parser_on_header_field
        parserSettings.on_header_value = http_parser_on_header_value
        parserSettings.on_headers_complete = http_parser_on_headers_complete
        parserSettings.on_body = http_parser_on_body
        parserSettings.on_message_complete = http_parser_on_message_complete
        
        self.parser = parser
        self.parserSettings = parserSettings
        
        self.parser.data = Unmanaged.passUnretained(self).toOpaque()
    }
    
    deinit {
        buffer.deallocate()
    }
    
    func headersComplete(context: Context, body: BodyStream, method: Int32, http_major: Int16, http_minor: Int16) -> Bool {
        return false
    }
    
    func read(deadline: Deadline) throws {
        let read = try stream.read(buffer, deadline: deadline)
        try parse(read)
    }
    
    private func parse(_ buffer: UnsafeRawBufferPointer) throws {
        let final = buffer.isEmpty
        let needsMessage: Bool
        
        switch state {
        case .ready, .messageComplete:
            needsMessage = false
        default:
            needsMessage = final
        }
        
        let processedCount: Int
        
        if final {
            processedCount = http_parser_execute(&parser, &parserSettings, nil, 0)
        } else {
            processedCount = http_parser_execute(
                &parser,
                &parserSettings,
                buffer.baseAddress?.assumingMemoryBound(to: Int8.self),
                buffer.count
            )
        }
        
        guard processedCount == buffer.count else {
            throw ParserError(parser.http_errno)
        }
        
        guard !needsMessage else {
            throw ParserError(HPE_INVALID_EOF_STATE.rawValue)
        }
    }
    
    fileprivate func process(state newState: State, data: UnsafeRawBufferPointer? = nil, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16) -> Int32 {
        if state != newState {
            switch state {
            case .ready, .messageBegin, .body, .messageComplete:
                break
            case .uri:
                guard let uri = bytes.withUnsafeBytes({ buffer in
                    return URI(buffer: buffer, isConnect: method == HTTP_CONNECT.rawValue)
                }) else {
                    return 1
                }
                
                context.uri = uri
            case .status:
                bytes.append(0)
                
                let string = bytes.withUnsafeBufferPointer { (pointer: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: pointer.baseAddress!)
                }
                context.status = Response.Status(
                   
                    statusCode: Int(status_code),
                    reasonPhrase: string
                )
            case .headerField:
                bytes.append(0)
                
                let string = bytes.withUnsafeBufferPointer { (pointer: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: pointer.baseAddress!)
                }
                
                context.currentHeaderField = Headers.Field(string)
            case .headerValue:
                bytes.append(0)
                
                let string = bytes.withUnsafeBufferPointer { (pointer: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: pointer.baseAddress!)
                }
                
                context.addValueForCurrentHeaderField(string)
            case .headersComplete:
                context.currentHeaderField = nil
                let body = BodyStream(parser: self)
                context.bodyStream = body
                
                if !headersComplete(context: context, body: body, method: method, http_major: http_major, http_minor: http_minor) {
                    return 1
                }
            }
            
            bytes = []
            state = newState
            
            if state == .messageComplete {
                context.bodyStream?.complete = true
                context = Context()
            }
        }
        
        guard let data = data, !data.isEmpty else {
            return 0
        }
        
        switch state {
        case .body:
            context.bodyStream?.bodyBuffer = data
        default:
            bytes.append(contentsOf: data)
        }
        
        return 0
    }
}

private func http_parser_on_message_begin(pointer: UnsafeMutablePointer<http_parser>?, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .messageBegin, method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_url(
    pointer: UnsafeMutablePointer<http_parser>?,
    data: UnsafePointer<Int8>?,
    length: Int, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16
) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .uri, data: UnsafeRawBufferPointer(start: data, count: length), method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_status(
    pointer: UnsafeMutablePointer<http_parser>?,
    data: UnsafePointer<Int8>?,
    length: Int, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16
) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .status, data: UnsafeRawBufferPointer(start: data, count: length), method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_header_field(
    pointer: UnsafeMutablePointer<http_parser>?,
    data: UnsafePointer<Int8>?,
    length: Int, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16
) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .headerField, data: UnsafeRawBufferPointer(start: data, count: length), method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_header_value(
    pointer: UnsafeMutablePointer<http_parser>?,
    data: UnsafePointer<Int8>?,
    length: Int, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16
) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .headerValue, data: UnsafeRawBufferPointer(start: data, count: length), method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_headers_complete(pointer: UnsafeMutablePointer<http_parser>?, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .headersComplete, method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_body(
    pointer: UnsafeMutablePointer<http_parser>?,
    data: UnsafePointer<Int8>?,
    length: Int, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16
) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .body, data: UnsafeRawBufferPointer(start: data, count: length), method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}

private func http_parser_on_message_complete(pointer: UnsafeMutablePointer<http_parser>?, method: Int32, status_code: Int32, http_major: Int16, http_minor: Int16) -> Int32 {
    let parser = Unmanaged<Parser>.fromOpaque(pointer!.pointee.data).takeUnretainedValue()
    return parser.process(state: .messageComplete, method: method, status_code: status_code, http_major: http_major, http_minor: http_minor)
}
