enum URLEncodedFormParseError : Error {
    case unsupportedEncoding
    case malformedURLEncodedForm
}

public struct URLEncodedFormParser {
    public init() {}

    public func parse(data: Data) throws -> URLEncodedForm {
        guard let string = try? String(data: data) else {
            throw URLEncodedFormParseError.unsupportedEncoding
        }

        var urlEncodedForm: URLEncodedForm = [:]

        for parameter in string.split(separator: "&") {
            var key = ""
            var value = ""
            var finishedKeyParsing = false
            for character in parameter.characters {
                guard !finishedKeyParsing else {
                    value.append(character)
                    continue
                }

                guard character != "=" else {
                    finishedKeyParsing = true
                    continue
                }

                key.append(character)
            }


            guard finishedKeyParsing else {
                throw URLEncodedFormParseError.malformedURLEncodedForm
            }

            urlEncodedForm.values[try String(percentEncoded: key)] = try String(percentEncoded: value)
        }

        return urlEncodedForm
    }
}
