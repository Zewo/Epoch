public struct ServerContentNegotiationMiddleware : Middleware {
    public enum Mode {
        case buffer
        case stream
    }

    public let mode: Mode
    public let types: [MediaTypeConverter.Type]

    var mediaTypes: [MediaType] {
        return types.map({$0.mediaType})
    }

    public init(mediaTypes: [MediaTypeConverter.Type], mode: Mode = .stream) {
        self.types = mediaTypes
        self.mode = mode
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        switch mode {
        case .buffer:
            return try bufferRespond(to: request, chainingTo: chain)
        case .stream:
            return try streamRespond(to: request, chainingTo: chain)
        }
    }

    public func bufferRespond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request

        let buffer = try request.body.becomeBuffer(deadline: .never)

        if let contentType = request.contentType {
            do {
                let (_, content) = try parse(buffer: buffer, deadline: .never, mediaType: contentType, in: types)
                request.content = content
            } catch ContentNegotiationMiddlewareError.noSuitableParser {
                throw HTTPError.unsupportedMediaType
            }
        }

        var response = try chain.respond(to: request)

        if let content = response.content {
            let mediaTypes = request.accept.isEmpty ? self.mediaTypes : request.accept
            let (mediaType, buffer) = try serializeToBuffer(from: content, deadline: .never, mediaTypes: mediaTypes, in: types)
            response.content = nil
            response.contentType = mediaType
            // TODO: Maybe add `willSet` to `body` and configure the headers there
            response.contentLength = buffer.count
            response.body = .buffer(buffer)
        }
        
        return response
    }

    public func streamRespond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request

        let stream = try request.body.becomeReader()

        if let contentType = request.contentType {
            do {
                let (_, content) = try parse(stream: stream, deadline: .never, mediaType: contentType, in: types)
                request.content = content
            } catch ContentNegotiationMiddlewareError.noSuitableParser {
                throw HTTPError.unsupportedMediaType
            }
        }

        var response = try chain.respond(to: request)

        if let content = response.content {
            let mediaTypes = request.accept.isEmpty ? self.mediaTypes : request.accept
            let (mediaType, writer) = try serializeToStream(from: content, deadline: .never, mediaTypes: mediaTypes, in: types)
            response.content = nil
            response.contentType = mediaType
            // TODO: Maybe add `willSet` to `body` and configure the headers there
            response.transferEncoding = "chunked"
            response.body = .writer(writer)
        }

        return response
    }
}
