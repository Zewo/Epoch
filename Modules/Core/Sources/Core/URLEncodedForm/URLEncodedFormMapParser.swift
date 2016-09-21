enum URLEncodedFormMapParserError : Error {
    case unsupportedEncoding
    case malformedURLEncodedForm
}

public struct URLEncodedFormMapParser : MapParser {
    public init() {}

    public func parse(_ buffer: Buffer) throws -> Map {
        guard let string = try? String(buffer: buffer) else {
            throw URLEncodedFormMapParserError.unsupportedEncoding
        }

        var map: Map = [:]

        for parameter in string.split(separator: "&") {
            let tokens = parameter.split(separator: "=")

            if tokens.count == 2 {
                let key = try String(percentEncoded: tokens[0])
                let value = try String(percentEncoded: tokens[1])

                map[key] = .string(value)
            } else {
                throw URLEncodedFormMapParserError.malformedURLEncodedForm
            }
        }

        return map
    }
}
