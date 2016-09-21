public enum ContentNegotiationMiddlewareError : Error {
    case noSuitableParser
    case noSuitableSerializer
}

public struct ContentNegotiationMiddleware : Middleware {
    public let types: [MediaTypeRepresentor.Type]
    public let mode: Mode

    public var mediaTypes: [MediaType] {
        return types.map({$0.mediaType})
    }

    public enum Mode {
        case server
        case client
    }

    public init(mediaTypes: [MediaTypeRepresentor.Type], mode: Mode = .server) {
        self.types = mediaTypes
        self.mode = mode
    }

    public func parsersFor(_ mediaType: MediaType) -> [(MediaType, MapParser)] {
        var parsers: [(MediaType, MapParser)] = []

        for type in types {
            if type.mediaType.matches(other: mediaType) {
                parsers.append(type.mediaType, type.parser)
            }
        }

        return parsers
    }

    public func parse(_ buffer: Buffer, mediaType: MediaType) throws -> (MediaType, Map) {
        var lastError: Error?

        for (mediaType, parser) in parsersFor(mediaType) {
            do {
                return try (mediaType, parser.parse(buffer))
            } catch {
                lastError = error
                continue
            }
        }

        if let lastError = lastError {
            throw lastError
        } else {
            throw ContentNegotiationMiddlewareError.noSuitableParser
        }
    }

    func serializersFor(_ mediaType: MediaType) -> [(MediaType, MapSerializer)] {
        var serializers: [(MediaType, MapSerializer)] = []

        for type in types {
            if type.mediaType.matches(other: mediaType) {
                serializers.append(type.mediaType, type.serializer)
            }
        }

        return serializers
    }

    public func serialize(_ content: Map) throws -> (MediaType, Buffer) {
        return try serialize(content, mediaTypes: mediaTypes)
    }

    func serialize(_ content: Map, mediaTypes: [MediaType]) throws -> (MediaType, Buffer) {
        var lastError: Error?

        for acceptedType in mediaTypes {
            for (mediaType, serializer) in serializersFor(acceptedType) {
                do {
                    return try (mediaType, serializer.serialize(content))
                } catch {
                    lastError = error
                    continue
                }
            }
        }

        if let lastError = lastError {
            throw lastError
        } else {
            throw ContentNegotiationMiddlewareError.noSuitableSerializer
        }
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        switch mode {
        case .server:
            return try respondServer(request, chain: chain)
        case .client:
            return try respondClient(request, chain: chain)
        }
    }

    public func respondServer(_ request: Request, chain: Responder) throws -> Response {
        var request = request

        let body = try request.body.becomeBuffer()

        if let contentType = request.contentType, !body.isEmpty {
            do {
                let (_, content) = try parse(body, mediaType: contentType)
                request.content = content
            } catch ContentNegotiationMiddlewareError.noSuitableParser {
                throw HTTPError.unsupportedMediaType
            }
        }

        var response = try chain.respond(to: request)

        if let content = response.content {
            do {
                let mediaTypes = !request.accept.isEmpty ? request.accept : self.mediaTypes
                let (mediaType, body) = try serialize(content, mediaTypes: mediaTypes)
                response.content = nil
                response.contentType = mediaType
                response.body = .buffer(body)
                response.contentLength = body.count
            } catch ContentNegotiationMiddlewareError.noSuitableSerializer {
                throw HTTPError.notAcceptable
            }
        }

        return response
    }

    public func respondClient(_ request: Request, chain: Responder) throws -> Response {
        var request = request

        request.accept = mediaTypes

        if let content = request.content {
            let (mediaType, body) = try serialize(content)
            request.contentType = mediaType
            request.body = .buffer(body)
            request.contentLength = body.count
        }

        var response = try chain.respond(to: request)

        let body = try response.body.becomeBuffer()

        if let contentType = response.contentType {
            let (_, content) = try parse(body, mediaType: contentType)
            response.content = content
        }

        return response
    }
}
