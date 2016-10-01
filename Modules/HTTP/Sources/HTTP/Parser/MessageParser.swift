import CHTTPParser
import Core

public typealias MessageParserError = http_errno

public final class MessageParser {
    public typealias Result = Message
    
    public enum Mode {
        case request
        case response
    }
    
    private enum State: Int {
        case ready = 1
        case messageBegin = 2
        case url = 3
        case status = 4
        case headerField = 5
        case headerValue = 6
        case headersComplete = 7
        case body = 8
        case messageComplete = 9
    }
    
    private class Context {
        var method: Request.Method? = nil
        var status: Response.Status? = nil
        var version: Version? = nil
        var url: URL? = nil
        var headers: [CaseInsensitiveString: String] = [:]
        var body = Buffer()
        
        var currentHeaderField: CaseInsensitiveString? = nil
        
        func addValueForCurrentHeaderField(_ value: String) {
            let key = currentHeaderField!

            if let existing = headers[key] {
                headers[key] = existing + ", " + value
            } else {
                headers[key] = value
            }
        }
    }
    
    public var parser: http_parser
    public var parserSettings: http_parser_settings
    public let mode: Mode
    
    private var state: State = .ready
    private var context = Context()
    private var buffer: [UInt8] = []
    
    private var messages: [Message] = []
    
    public init(mode: Mode) {
        var parser = http_parser()
        
        switch mode {
        case .request:
            http_parser_init(&parser, HTTP_REQUEST)
        case .response:
            http_parser_init(&parser, HTTP_RESPONSE)
        }
        
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
        self.mode = mode
        
        self.parser.data = Unmanaged.passUnretained(self).toOpaque()
    }
    
    public func parse(_ from: BufferRepresentable) throws -> [Message] {
        let buffer = from.buffer

        return try buffer.withUnsafeBytes {
            try self.parse(UnsafeBufferPointer(start: $0, count: buffer.count))
        }
    }
    
    public func parse(_ from: UnsafeBufferPointer<UInt8>) throws -> [Message] {
        if !from.isEmpty {
            let processedCount = from.baseAddress!.withMemoryRebound(to: Int8.self, capacity: from.count) {
                return http_parser_execute(&self.parser, &self.parserSettings, $0, from.count)
            }

            guard processedCount == from.count else {
                throw MessageParserError(parser.http_errno)
            }
        }
        
        let parsed = messages
        messages = []
        return parsed
    }
    
    fileprivate func processOnMessageBegin() -> Int32 {
        return process(state: .messageBegin)
    }
    
    fileprivate func processOnURL(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        return process(state: .url, data: UnsafeBufferPointer<Int8>(start: data, count: length))
    }
    
    fileprivate func processOnStatus(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        return process(state: .status, data: UnsafeBufferPointer<Int8>(start: data, count: length))
    }
    
    fileprivate func processOnHeaderField(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        return process(state: .headerField, data: UnsafeBufferPointer<Int8>(start: data, count: length))
    }
    
    fileprivate func processOnHeaderValue(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        return process(state: .headerValue, data: UnsafeBufferPointer<Int8>(start: data, count: length))
    }
    
    fileprivate func processOnHeadersComplete() -> Int32 {
        return process(state: .headersComplete)
    }
    
    fileprivate func processOnBody(data: UnsafePointer<Int8>, length: Int) -> Int32 {
        return process(state: .body, data: UnsafeBufferPointer<Int8>(start: data, count: length))
    }
    
    fileprivate func processOnMessageComplete() -> Int32 {
        return process(state: .messageComplete)
    }
    
    fileprivate func process(state newState: State, data: UnsafeBufferPointer<Int8>? = nil) -> Int32 {
        if state != newState {
            switch state {
            case .ready, .messageBegin, .messageComplete:
                break
            case .url:
                buffer.append(0)

                let string = buffer.withUnsafeBufferPointer { (ptr: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: ptr.baseAddress!)
                }

                context.url = URL(string: string)!
            case .status:
                buffer.append(0)

                let string = buffer.withUnsafeBufferPointer { (ptr: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: ptr.baseAddress!)
                }

                context.status = Response.Status(
                    statusCode: Int(parser.status_code),
                    reasonPhrase: string
                )
            case .headerField:
                buffer.append(0)

                let string = buffer.withUnsafeBufferPointer { (ptr: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: ptr.baseAddress!)
                }

                context.currentHeaderField = CaseInsensitiveString(string)
            case .headerValue:
                buffer.append(0)

                let string = buffer.withUnsafeBufferPointer { (ptr: UnsafeBufferPointer<UInt8>) -> String in
                    return String(cString: ptr.baseAddress!)
                }

                context.addValueForCurrentHeaderField(string)
            case .headersComplete:
                context.currentHeaderField = nil
                context.method = Request.Method(code: http_method(rawValue: parser.method))
                context.version = Version(major: Int(parser.http_major), minor: Int(parser.http_minor))
            case .body:
                context.body = Buffer(buffer)
            }
            
            buffer = []
            state = newState
            
            if state == .messageComplete {
                let message: Message
                switch mode {
                case .request:
                    var request = Request(
                        method: context.method!,
                        url: context.url!,
                        headers: Headers(),
                        body: .buffer(context.body)
                    )

                    request.headers = Headers(context.headers)
                    message = request
                case .response:
                    let cookieHeaders =
                        self.context.headers
                            .filter { $0.key == "Set-Cookie" }
                            .map { $0.value }
                            .reduce(Set<String>()) { initial, value in
                                return initial.union(Set(value.components(separatedBy: ", ")))
                            }
                    
                    let response = Response(
                        version: context.version!,
                        status: context.status!,
                        headers: Headers(context.headers),
                        cookieHeaders: cookieHeaders,
                        body: .buffer(context.body)
                    )
                    
                    message = response
                }
                
                messages.append(message)
                context = Context()
            }
        }

        guard let data = data, data.count > 0 else {
            return 0
        }
        
        data.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: data.count) { ptr in
            for i in 0..<data.count {
                self.buffer.append(ptr[i])
            }
        }

        return 0
    }
}

extension MessageParserError : Error, CustomStringConvertible {
    public var description: String {
        return String(cString: http_errno_description(self))
    }
}

extension Request.Method {
    internal init(code: http_method) {
        switch code {
        case HTTP_DELETE: self = .delete
        case HTTP_GET: self = .get
        case HTTP_HEAD: self = .head
        case HTTP_POST: self = .post
        case HTTP_PUT: self = .put
        case HTTP_CONNECT: self = .connect
        case HTTP_OPTIONS: self = .options
        case HTTP_TRACE: self = .trace
        case HTTP_COPY: self = .other(method: "COPY")
        case HTTP_LOCK: self = .other(method: "LOCK")
        case HTTP_MKCOL: self = .other(method: "MKCOL")
        case HTTP_MOVE: self = .other(method: "MOVE")
        case HTTP_PROPFIND: self = .other(method: "PROPFIND")
        case HTTP_PROPPATCH: self = .other(method: "PROPPATCH")
        case HTTP_SEARCH: self = .other(method: "SEARCH")
        case HTTP_UNLOCK: self = .other(method: "UNLOCK")
        case HTTP_BIND: self = .other(method: "BIND")
        case HTTP_REBIND: self = .other(method: "REBIND")
        case HTTP_UNBIND: self = .other(method: "UNBIND")
        case HTTP_ACL: self = .other(method: "ACL")
        case HTTP_REPORT: self = .other(method: "REPORT")
        case HTTP_MKACTIVITY: self = .other(method: "MKACTIVITY")
        case HTTP_CHECKOUT: self = .other(method: "CHECKOUT")
        case HTTP_MERGE: self = .other(method: "MERGE")
        case HTTP_MSEARCH: self = .other(method: "M-SEARCH")
        case HTTP_NOTIFY: self = .other(method: "NOTIFY")
        case HTTP_SUBSCRIBE: self = .other(method: "SUBSCRIBE")
        case HTTP_UNSUBSCRIBE: self = .other(method: "UNSUBSCRIBE")
        case HTTP_PATCH: self = .patch
        case HTTP_PURGE: self = .other(method: "PURGE")
        case HTTP_MKCALENDAR: self = .other(method: "MKCALENDAR")
        case HTTP_LINK: self = .other(method: "LINK")
        case HTTP_UNLINK: self = .other(method: "UNLINK")
        default: self = .other(method: "UNKNOWN")
        }
    }
}

private func http_parser_on_message_begin(ctx: UnsafeMutablePointer<http_parser>?) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnMessageBegin()
}

private func http_parser_on_url(ctx: UnsafeMutablePointer<http_parser>?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnURL(data: data!, length: length)
}

private func http_parser_on_status(ctx: UnsafeMutablePointer<http_parser>?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnStatus(data: data!, length: length)
}

private func http_parser_on_header_field(ctx: UnsafeMutablePointer<http_parser>?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnHeaderField(data: data!, length: length)
}

private func http_parser_on_header_value(ctx: UnsafeMutablePointer<http_parser>?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnHeaderValue(data: data!, length: length)
}

private func http_parser_on_headers_complete(ctx: UnsafeMutablePointer<http_parser>?) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnHeadersComplete()
}

private func http_parser_on_body(ctx: UnsafeMutablePointer<http_parser>?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnBody(data: data!, length: length)
}

private func http_parser_on_message_complete(ctx: UnsafeMutablePointer<http_parser>?) -> Int32 {
    let ref = Unmanaged<MessageParser>.fromOpaque(ctx!.pointee.data).takeUnretainedValue()
    return ref.processOnMessageComplete()
}
