public enum ContentNegotiationMiddlewareError : Error {
    case noSuitableParser
    case noSuitableSerializer
    case writerBodyNotSupported
}

public struct ContentNegotiationMiddleware : Middleware {
    public enum Mode {
        case server
        case client
    }

    public enum SerializationMode {
        case buffer
        case stream
    }

    private let converters: [MediaTypeConverter]
    private let mediaTypes: [MediaType]
    private let mode: Mode
    private let serializationMode: SerializationMode

    public init(mediaTypes: [MediaTypeConverter], mode: Mode = .server, serializationMode: SerializationMode = .stream) {
        self.converters = mediaTypes
        self.mediaTypes = converters.map({$0.mediaType})
        self.mode = mode
        self.serializationMode = serializationMode
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        switch mode {
        case .server:
            return try serverRespond(to: request, chainingTo: chain)
        case .client:
            return try clientRespond(to: request, chainingTo: chain)
        }
    }

    private func serverRespond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request

        if let contentType = request.contentType {
            do {
                let content: Map

                switch request.body {
                case .buffer(let buffer):
                        content = try parse(buffer: buffer, mediaType: contentType)
                case .reader(let stream):
                        content = try parse(stream: stream, deadline: .never, mediaType: contentType)
                case .writer:
                    // TODO: Deal with writer bodies
                    throw ContentNegotiationMiddlewareError.writerBodyNotSupported
                }
                request.content = content
            } catch ContentNegotiationMiddlewareError.noSuitableParser {
                throw HTTPError.unsupportedMediaType
            }
        }

        var response = try chain.respond(to: request)

        if let content = response.content {
            let mediaTypes: [MediaType]

            if let contentType = response.contentType {
                mediaTypes = [contentType]
            } else {
                mediaTypes = request.accept.isEmpty ? self.mediaTypes : request.accept
            }

            response.content = nil

            switch serializationMode {
            case .buffer:
                let (mediaType, buffer) = try serializeToBuffer(from: content, mediaTypes: mediaTypes)
                response.contentType = mediaType
                // TODO: Maybe add `willSet` to `body` and configure the headers there
                response.transferEncoding = nil
                response.contentLength = buffer.count
                response.body = .buffer(buffer)
            case .stream:
                let (mediaType, writer) = try serializeToStream(from: content, deadline: .never, mediaTypes: mediaTypes)
                response.contentType = mediaType
                // TODO: Maybe add `willSet` to `body` and configure the headers there
                response.contentLength = nil
                response.transferEncoding = "chunked"
                response.body = .writer(writer)
            }
        }

        return response
    }

    private func clientRespond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request

        request.accept = mediaTypes

        if let content = request.content {
            let mediaTypes: [MediaType]

            if let contentType = request.contentType {
                mediaTypes = [contentType]
            } else {
                mediaTypes = self.mediaTypes
            }

            request.content = nil

            switch serializationMode {
            case .buffer:
                let (mediaType, buffer) = try serializeToBuffer(from: content, mediaTypes: mediaTypes)
                request.contentType = mediaType
                // TODO: Maybe add `willSet` to `body` and configure the headers there
                request.transferEncoding = nil
                request.contentLength = buffer.count
                request.body = .buffer(buffer)
            case .stream:
                let (mediaType, writer) = try serializeToStream(from: content, deadline: .never, mediaTypes: mediaTypes)
                request.contentType = mediaType
                // TODO: Maybe add `willSet` to `body` and configure the headers there
                request.contentLength = nil
                request.transferEncoding = "chunked"
                request.body = .writer(writer)
            }
        }

        var response = try chain.respond(to: request)

        if let contentType = response.contentType {
            let content: Map

            switch response.body {
            case .buffer(let buffer):
                content = try parse(buffer: buffer, mediaType: contentType)
            case .reader(let stream):
                content = try parse(stream: stream, deadline: .never, mediaType: contentType)
            case .writer:
                // TODO: Deal with writer bodies
                throw ContentNegotiationMiddlewareError.writerBodyNotSupported
            }

            response.content = content
        }

        return response
    }

    private func parserTypes(for mediaType: MediaType) -> [MapParser.Type] {
        var parsers: [MapParser.Type] = []

        for converter in converters where converter.mediaType.matches(other: mediaType) {
            parsers.append(converter.parser)
        }

        return parsers
    }

    private func firstParserType(for mediaType: MediaType) throws -> MapParser.Type {
        guard let first = parserTypes(for: mediaType).first else {
            throw ContentNegotiationMiddlewareError.noSuitableParser
        }

        return first
    }

    private func serializerTypes(for mediaType: MediaType) -> [(MediaType, MapSerializer.Type)] {
        var serializers: [(MediaType, MapSerializer.Type)] = []

        for converter in converters where converter.mediaType.matches(other: mediaType) {
            serializers.append(converter.mediaType, converter.serializer)
        }

        return serializers
    }

    private func firstSerializerType(for mediaType: MediaType) throws -> (MediaType, MapSerializer.Type) {
        guard let first = serializerTypes(for: mediaType).first else {
            throw ContentNegotiationMiddlewareError.noSuitableSerializer
        }

        return first
    }

    private func parse(stream: InputStream, deadline: Double, mediaType: MediaType) throws -> Map {
        let parserType = try firstParserType(for: mediaType)

        do {
            return try parserType.parse(stream, deadline: deadline)
        } catch {
            throw ContentNegotiationMiddlewareError.noSuitableParser
        }
    }

    private func parse(buffer: Buffer, mediaType: MediaType) throws -> Map {
        var lastError: Error?

        for parserType in parserTypes(for: mediaType) {
            do {
                return try parserType.parse(buffer)
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

    private func serializeToStream(from content: Map, deadline: Double, mediaTypes: [MediaType]) throws -> (MediaType, (OutputStream) throws -> Void)  {
        for acceptedType in mediaTypes {
            for (mediaType, serializerType) in serializerTypes(for: acceptedType) {
                return (mediaType, { stream in
                    try serializerType.serialize(content, stream: stream, deadline: deadline)
                })
            }
        }

        throw ContentNegotiationMiddlewareError.noSuitableSerializer
    }

    private func serializeToBuffer(from content: Map, mediaTypes: [MediaType]) throws -> (MediaType, Buffer) {
        var lastError: Error?

        for acceptedType in mediaTypes {
            for (mediaType, serializerType) in serializerTypes(for: acceptedType) {
                do {
                    let buffer = try serializerType.serialize(content)
                    return (mediaType, buffer)
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
}
