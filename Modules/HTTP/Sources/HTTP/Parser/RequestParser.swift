import CHTTPParser

typealias RequestContext = UnsafeMutablePointer<RequestParserContext>

struct RequestParserContext {
    var method: Request.Method! = nil
    var url: URL! = nil
    var version: Version = Version(major: 0, minor: 0)
    var headers: Headers = Headers([:])
    var body: Data = Data()

    var currentURI = ""
    var buildingHeaderName = ""
    var currentHeaderName: CaseInsensitiveString = ""
    var completion: (Request) -> Void

    init(completion: @escaping (Request) -> Void) {
        self.completion = completion
    }
}

var requestSettings: http_parser_settings = {
    var settings = http_parser_settings()
    http_parser_settings_init(&settings)

    settings.on_url              = onRequestURL
    settings.on_header_field     = onRequestHeaderField
    settings.on_header_value     = onRequestHeaderValue
    settings.on_headers_complete = onRequestHeadersComplete
    settings.on_body             = onRequestBody
    settings.on_message_complete = onRequestMessageComplete

    return settings
}()

public final class RequestParser {
    let stream: Stream
    let context: RequestContext
    var parser = http_parser()
    var requests: [Request] = []
    var buffer: Data

    public init(stream: Stream, bufferSize: Int = 2048) {
        self.stream = stream
        self.buffer = Data(count: bufferSize)
        self.context = RequestContext.allocate(capacity: 1)
        self.context.initialize(to: RequestParserContext { [unowned self] request in
            self.requests.insert(request, at: 0)
        })

        resetParser()
    }

    deinit {
        context.deallocate(capacity: 1)
    }

    func resetParser() {
        http_parser_init(&parser, HTTP_REQUEST)
        parser.data = UnsafeMutableRawPointer(context)
    }

    public func parse() throws -> Request {
        while true {
            if let request = requests.popLast() {
                return request
            }

            let bytesRead = try stream.read(into: &buffer)
            let bytesParsed = buffer.withUnsafeBytes {
                http_parser_execute(&parser, &requestSettings, $0, bytesRead)
            }

            guard bytesParsed == bytesRead else {
                defer { resetParser() }
                throw http_errno(parser.http_errno)
            }
        }
    }
}

func onRequestURL(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestParserContext.self).withPointee {
        let uri = String(cString: data!, length: length)
        $0.currentURI += uri
        return 0
    }
}

func onRequestHeaderField(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestParserContext.self).withPointee {
        let headerName = String(cString: data!, length: length)

        if $0.currentHeaderName != "" {
            $0.currentHeaderName = ""
        }

        $0.buildingHeaderName += headerName
        return 0
    }
}

func onRequestHeaderValue(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestParserContext.self).withPointee {
        let headerValue = String(cString: data!, length: length)

        if $0.currentHeaderName == "" {
            $0.currentHeaderName = CaseInsensitiveString($0.buildingHeaderName)
            $0.buildingHeaderName = ""

            if let previousHeaderValue = $0.headers[$0.currentHeaderName] {
                $0.headers[$0.currentHeaderName] = previousHeaderValue + ", "
            }
        }

        let previousHeaderValue = $0.headers[$0.currentHeaderName] ?? ""
        $0.headers[$0.currentHeaderName] = previousHeaderValue + headerValue

        return 0
    }
}

func onRequestHeadersComplete(_ parser: Parser?) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestParserContext.self).withPointee {
        $0.method = Request.Method(code: Int(parser!.pointee.method))
        let major = Int(parser!.pointee.http_major)
        let minor = Int(parser!.pointee.http_minor)
        $0.version = Version(major: major, minor: minor)

        $0.url = URL(string: $0.currentURI)!
        $0.currentURI = ""
        $0.buildingHeaderName = ""
        $0.currentHeaderName = ""
        return 0
    }
}

func onRequestBody(_ parser: Parser?, data: UnsafePointer<Int8>?, length: Int) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestParserContext.self).withPointee { context in
        data!.withMemoryRebound(to: UInt8.self, capacity: length) { bytes in
            context.body.append(bytes, count: length)
        }
        return 0
    }
}

func onRequestMessageComplete(_ parser: Parser?) -> Int32 {
    return parser!.pointee.data.assumingMemoryBound(to: RequestParserContext.self).withPointee {
        let request = Request(
            method: $0.method,
            url: $0.url,
            version: $0.version,
            headers: $0.headers,
            body: .buffer($0.body)
        )

        $0.completion(request)

        $0.method = nil
        $0.url = nil
        $0.version = Version(major: 0, minor: 0)
        $0.headers = Headers([:])
        $0.body = Data()
        return 0
    }
}
