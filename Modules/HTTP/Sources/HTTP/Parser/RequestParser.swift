import CHTTPParser
import Foundation


struct RequestParserContext {
    var method: Request.Method! = nil
    var url: URL! = nil
    var version: Version = Version(major: 0, minor: 0)
    var headers: Headers = Headers([:])
    var body: Buffer = Buffer()
    
    
    var currentHeaderField: String? = nil
}

enum RequestParserState: Int {
    case none = 1
    case url = 2
    case messageBegin = 3
    case headerField = 4
    case headerValue = 5
    case headersComplete = 6
    case body = 7
    case messageComplete = 8
}

public final class RequestParser {
    let stream: Core.Stream
    var parser = http_parser()
    var parserSettings: http_parser_settings
    var parserBuffer: [UInt8] = []
    var parserContext: RequestParserContext = RequestParserContext()
    var parserState: RequestParserState = .none
    var requests: [Request] = []
    
    let bufferBytes: UnsafeMutablePointer<UInt8>
    let buffer: UnsafeMutableBufferPointer<UInt8>
    
    
    public init(stream: Core.Stream, bufferSize: Int = 4096) {
        self.stream = stream
        self.bufferBytes = UnsafeMutablePointer.allocate(capacity: bufferSize)
        self.buffer = UnsafeMutableBufferPointer(start: bufferBytes, count: bufferSize)
        
        var parserSettings = http_parser_settings()
        http_parser_settings_init(&parserSettings)
        
        parserSettings.on_message_begin = { (parser: Parser?) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnMessageBegin()
        }
        parserSettings.on_url = { (parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnURL(data: data!, length: length)
        }
        parserSettings.on_header_field = { (parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnHeaderField(data: data!, length: length)
        }
        parserSettings.on_header_value = { (parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnHeaderValue(data: data!, length: length)
        }
        parserSettings.on_headers_complete = { (parser: Parser?) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnHeadersComplete()
        }
        parserSettings.on_body = { (parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnBody(data: data!, length: length)
        }
        parserSettings.on_message_complete = { (parser: Parser?) -> Int32 in
            let ref = Unmanaged<RequestParser>.fromOpaque(parser!.pointee.data).takeUnretainedValue()
            return ref.parserOnMessageComplete()
        }
        
        self.parserSettings = parserSettings
        
        resetParser()
    }
    deinit {
        bufferBytes.deallocate(capacity: buffer.count)
    }

    public func parse() throws -> Request {
        while true {
            if let request = requests.popLast() {
                return request
            }

            let bytesRead = try stream.read(into: buffer)
            let bytesParsed = buffer.baseAddress!.withMemoryRebound(to: Int8.self, capacity: buffer.count) {
                http_parser_execute(&parser, &parserSettings, $0, bytesRead)
            }
            
            guard bytesParsed == bytesRead else {
                defer { resetParser() }
                throw http_errno(parser.http_errno)
            }
        }
    }
    
    func resetParser() {
        http_parser_init(&parser, HTTP_REQUEST)
        parser.data = Unmanaged.passUnretained(self).toOpaque()
        parserState = .none
        parserContext = RequestParserContext()
    }
    
    func parserOnMessageBegin() -> Int32 {
        parserProcess(state: .messageBegin)
        return 0
    }
    
    func parserOnURL(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        parserProcess(state: .url, data: UnsafeBufferPointer<Int8>(start: data, count: length))
        return 0
    }
    
    func parserOnHeaderField(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        parserProcess(state: .headerField, data: UnsafeBufferPointer<Int8>(start: data, count: length))
        return 0
    }
    
    func parserOnHeaderValue(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        parserProcess(state: .headerValue, data: UnsafeBufferPointer<Int8>(start: data, count: length))
        return 0
    }
    
    func parserOnHeadersComplete() -> Int32 {
        parserProcess(state: .headersComplete)
        return 0
    }
    
    func parserOnBody(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        parserProcess(state: .body, data: UnsafeBufferPointer<Int8>(start: data, count: length))
        return 0
    }
    
    func parserOnMessageComplete() -> Int32 {
        parserProcess(state: .messageComplete)
        return 0
    }
    
    func parserProcess(state: RequestParserState, data: UnsafeBufferPointer<Int8>? = nil) {
        if parserState != state {
            
            switch parserState {
            case .none, .messageBegin, .messageComplete:
                break
                
            case .url:
                let str = String(bytes: parserBuffer, encoding: String.Encoding.utf8)!
                parserContext.url = URL(string: str)!
                
            case .headerField:
                let str = String(bytes: parserBuffer, encoding: String.Encoding.utf8)!
                parserContext.currentHeaderField = str
                
            case .headerValue:
                let field = CaseInsensitiveString(parserContext.currentHeaderField!)
                let str = String(bytes: parserBuffer, encoding: String.Encoding.utf8)!
                
                if let existing = parserContext.headers[field] {
                    parserContext.headers[field] = "\(existing), \(str)"
                } else {
                    parserContext.headers[field] = str
                }
                
                parserContext.currentHeaderField = nil
                
            case .headersComplete:
                parserContext.method = Request.Method(code: Int(parser.method))
                parserContext.version = Version(major: Int(parser.http_major), minor: Int(parser.http_minor))
                parserContext.currentHeaderField = nil
                
            case .body:
                parserContext.body = Buffer(parserBuffer)
            }
            
            parserBuffer = []
            parserState = state
            
            if state == .messageComplete {
                let request = Request(
                    method: parserContext.method,
                    url: parserContext.url,
                    version: parserContext.version,
                    headers: parserContext.headers,
                    body: .buffer(parserContext.body)
                )
                requests.append(request)
                resetParser()
                return
            }
        }
        
        
        
        guard let data = data, data.count > 0 else {
            return
        }
        
        data.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: data.count) { ptr in
            for i in 0..<data.count {
                parserBuffer.append(ptr[i])
            }
        }
    }
}
