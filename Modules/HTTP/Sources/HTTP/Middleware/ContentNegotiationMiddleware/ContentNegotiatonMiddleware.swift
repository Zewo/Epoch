public enum ContentNegotiationMiddlewareError : Error {
    case noSuitableParser
    case noSuitableSerializer
}

func parserTypes(for mediaType: MediaType, `in` types: [MediaTypeConverter.Type]) -> [(MediaType, MapParser.Type)] {
    var parsers: [(MediaType, MapParser.Type)] = []

    for type in types where type.mediaType.matches(other: mediaType) {
        parsers.append(type.mediaType, type.parser)
    }

    return parsers
}

func firstParserType(for mediaType: MediaType, `in` types: [MediaTypeConverter.Type]) throws -> (MediaType, MapParser.Type) {
    guard let first = parserTypes(for: mediaType, in: types).first else {
        throw ContentNegotiationMiddlewareError.noSuitableParser
    }

    return first
}

func serializerTypes(for mediaType: MediaType, `in` types: [MediaTypeConverter.Type]) -> [(MediaType, MapSerializer.Type)] {
    var serializers: [(MediaType, MapSerializer.Type)] = []

    for type in types where type.mediaType.matches(other: mediaType) {
        serializers.append(type.mediaType, type.serializer)
    }

    return serializers
}

func firstSerializerType(for mediaType: MediaType, `in` types: [MediaTypeConverter.Type]) throws -> (MediaType, MapSerializer.Type) {
    guard let first = serializerTypes(for: mediaType, in: types).first else {
        throw ContentNegotiationMiddlewareError.noSuitableSerializer
    }

    return first
}

func parse(stream: InputStream, deadline: Double, mediaType: MediaType, `in` types: [MediaTypeConverter.Type]) throws -> (MediaType, Map) {
    let (mediaType, parserType) = try firstParserType(for: mediaType, in: types)

    do {
        let content = try parserType.parse(stream, deadline: deadline)
        return (mediaType, content)
    } catch {
        throw ContentNegotiationMiddlewareError.noSuitableParser
    }
}

func parse(buffer: Buffer, deadline: Double, mediaType: MediaType, `in` types: [MediaTypeConverter.Type]) throws -> (MediaType, Map) {
    var lastError: Error?

    for (mediaType, parserType) in parserTypes(for: mediaType, in: types) {
        do {
            let content = try parserType.parse(buffer)
            return (mediaType, content)
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

func serializeToStream(from content: Map, deadline: Double, mediaTypes: [MediaType], `in` types: [MediaTypeConverter.Type]) throws -> (MediaType, (OutputStream) throws -> Void)  {
    for acceptedType in mediaTypes {
        for (mediaType, serializerType) in serializerTypes(for: acceptedType, in: types) {
            return (mediaType, { stream in
                try serializerType.serialize(content, stream: stream, deadline: deadline)
            })
        }
    }

    throw ContentNegotiationMiddlewareError.noSuitableSerializer
}

func serializeToBuffer(from content: Map, deadline: Double, mediaTypes: [MediaType], `in` types: [MediaTypeConverter.Type]) throws -> (MediaType, Buffer) {
    var lastError: Error?

    for acceptedType in mediaTypes {
        for (mediaType, serializerType) in serializerTypes(for: acceptedType, in: types) {
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
