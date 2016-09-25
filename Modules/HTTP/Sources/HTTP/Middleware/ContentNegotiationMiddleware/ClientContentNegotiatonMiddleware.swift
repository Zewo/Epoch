public struct ClientContentNegotiationMiddleware : Middleware {
    public enum Mode {
        case buffer
        case stream
    }

    public let mode: Mode
    public let types: [MediaTypeConvertible.Type]

    var mediaTypes: [MediaType] {
        return types.map({$0.mediaType})
    }

    public init(mediaTypes: [MediaTypeConvertible.Type], mode: Mode = .stream) {
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

        request.accept = mediaTypes

        if let content = request.content {
            let (mediaType, buffer) = try serializeToBuffer(from: content, deadline: .never, mediaTypes: mediaTypes, in: types)
            request.contentType = mediaType
            request.body = .buffer(buffer)
            request.contentLength = buffer.count
        }

        var response = try chain.respond(to: request)

        let buffer = try response.body.becomeBuffer(deadline: .never)

        if let contentType = response.contentType {
            let (_, content) = try parse(buffer: buffer, deadline: .never, mediaType: contentType, in: types)
            response.content = content
        }
        
        return response
    }

    public func streamRespond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request

        request.accept = mediaTypes

        if let content = request.content {
            let (mediaType, writer) = try serializeToStream(from: content, deadline: .never, mediaTypes: mediaTypes, in: types)
            request.contentType = mediaType
            request.body = .writer(writer)
        }

        var response = try chain.respond(to: request)

        let stream = try response.body.becomeReader()

        if let contentType = response.contentType {
            let (_, content) = try parse(stream: stream, deadline: .never, mediaType: contentType, in: types)
            response.content = content
        }
        
        return response
    }
}
