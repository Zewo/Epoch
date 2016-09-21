import CHTTPParser

typealias ResponseContext = UnsafeMutablePointer<ResponseParserContext>

struct ResponseParserContext {
    var statusCode: Int = 0
    var reasonPhrase: String = ""
    var version: Version = Version(major: 0, minor: 0)
    var headers: Headers = [:]
    var cookieHeaders: Set<String> = []
    var body: Buffer = Buffer()

    var buildingHeaderName = ""
    var buildingCookieValue = ""
    var currentHeaderName: CaseInsensitiveString = ""
    var completion: (Response) -> Void

    init(completion: @escaping (Response) -> Void) {
        self.completion = completion
    }
}

var responseSettings: http_parser_settings = {
    var settings = http_parser_settings()
    http_parser_settings_init(&settings)

    settings.on_status           = onResponseStatus
    settings.on_header_field     = onResponseHeaderField
    settings.on_header_value     = onResponseHeaderValue
    settings.on_headers_complete = onResponseHeadersComplete
    settings.on_body             = onResponseBody
    settings.on_message_complete = onResponseMessageComplete

    return settings
}()

public final class ResponseParser {
    let stream: Stream
    let context: ResponseContext
    var parser = http_parser()
    var responses: [Response] = []
    var bufferSize: Int

    public init(stream: Stream, bufferSize: Int = 2048) {
        self.stream = stream
        self.bufferSize = bufferSize
        self.context = ResponseContext.allocate(capacity: 1)
        self.context.initialize(to: ResponseParserContext { [unowned self] response in
            self.responses.insert(response, at: 0)
        })

        resetParser()
    }

    deinit {
        context.deallocate(capacity: 1)
    }

    func resetParser() {
        http_parser_init(&parser, HTTP_RESPONSE)
        parser.data = UnsafeMutableRawPointer(context)
    }

    public func parse(deadline: Double = .never) throws -> Response {
        while true {
            if let response = responses.popLast() {
                return response
            }

            let buffer: Buffer
            do {
                buffer = try stream.read(upTo: bufferSize, deadline: deadline)
            } catch StreamError.closedStream {
                buffer = Buffer()
            }

            let bytesParsed = buffer.withUnsafeBytes {
                http_parser_execute(&parser, &responseSettings, $0, buffer.count)
            }

            guard bytesParsed == buffer.count else {
                defer { resetParser() }
                throw http_errno(parser.http_errno)
            }
        }
    }
}

func onResponseStatus(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: ResponseParserContext.self).withPointee {
        let reasonPhrase = String(cString: data!, length: length)
        $0.reasonPhrase += reasonPhrase
        return 0
    }
}

func onResponseHeaderField(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: ResponseParserContext.self).withPointee {
        let headerName = String(cString: data!, length: length)

        if $0.currentHeaderName != "" {
            $0.currentHeaderName = ""
        }

        if $0.buildingCookieValue != "" {
            $0.cookieHeaders.insert($0.buildingCookieValue)
            $0.buildingCookieValue = ""
        }

        $0.buildingHeaderName += headerName
        return 0
    }
}

func onResponseHeaderValue(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: ResponseParserContext.self).withPointee {
        let headerValue = String(cString: data!, length: length)

        if $0.currentHeaderName == "" {
            $0.currentHeaderName = CaseInsensitiveString($0.buildingHeaderName)
            $0.buildingHeaderName = ""

            if let previousHeaderValue = $0.headers[$0.currentHeaderName] {
                $0.headers[$0.currentHeaderName] = previousHeaderValue + ", "
            }
        }

        if $0.currentHeaderName == "Set-Cookie" {
            $0.buildingCookieValue += headerValue
        } else {
            let previousHeaderValue = $0.headers[$0.currentHeaderName] ?? ""
            $0.headers[$0.currentHeaderName] = previousHeaderValue + headerValue
        }

        return 0
    }
}

func onResponseHeadersComplete(_ parser: Parser?) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: ResponseParserContext.self).withPointee {
        if $0.buildingCookieValue != "" {
            $0.cookieHeaders.insert($0.buildingCookieValue)
            $0.buildingCookieValue = ""
        }

        $0.buildingHeaderName = ""
        $0.currentHeaderName = ""
        $0.statusCode = Int(parser!.pointee.status_code)
        let major = Int(parser!.pointee.http_major)
        let minor = Int(parser!.pointee.http_minor)
        $0.version = Version(major: major, minor: minor)
        return 0
    }
}

func onResponseBody(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: ResponseParserContext.self).withPointee {
        let buffer = UnsafeBufferPointer(start: data, count: length)
        $0.body.append(buffer)
        return 0
    }
}

func onResponseMessageComplete(_ parser: Parser?) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: ResponseParserContext.self).withPointee {
        let response = Response(
            version: $0.version,
            status: Response.Status(statusCode: $0.statusCode, reasonPhrase: $0.reasonPhrase),
            headers: $0.headers,
            cookieHeaders: $0.cookieHeaders,
            body: .buffer($0.body)
        )

        $0.completion(response)
        $0.statusCode = 0
        $0.reasonPhrase = ""
        $0.version = Version(major: 0, minor: 0)
        $0.headers = [:]
        $0.cookieHeaders = []
        $0.body = Buffer()
        return 0
    }
}
