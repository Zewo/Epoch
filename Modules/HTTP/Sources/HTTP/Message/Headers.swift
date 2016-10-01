public struct Headers {
    public var headers: [CaseInsensitiveString: String]

    public init(_ headers: [CaseInsensitiveString: String]) {
        self.headers = headers
    }
}

extension Headers : ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (CaseInsensitiveString, String)...) {
        var headers: [CaseInsensitiveString: String] = [:]

        for (key, value) in elements {
            headers[key] = value
        }

        self.headers = headers
    }
}

extension Headers : Sequence {
    public func makeIterator() -> DictionaryIterator<CaseInsensitiveString, String> {
        return headers.makeIterator()
    }

    public var count: Int {
        return headers.count
    }

    public var isEmpty: Bool {
        return headers.isEmpty
    }

    public subscript(field: CaseInsensitiveString) -> String? {
        get {
            return headers[field]
        }

        set(header) {
            headers[field] = header
            
            if field == "Content-Length" && header != nil && headers["Transfer-Encoding"] == "chunked" {
                headers["Transfer-Encoding"] = nil
            } else if field == "Transfer-Encoding" && header == "chunked" {
                headers["Content-Length"] = nil
            }
        }
    }

    public subscript(field: CaseInsensitiveStringRepresentable) -> String? {
        get {
            return self[field.caseInsensitiveString]
        }

        set(header) {
            self[field.caseInsensitiveString] = header
        }
    }
}

extension Headers : CustomStringConvertible {
    public var description: String {
        var string = ""

        for (header, value) in headers {
            string += "\(header): \(value)\n"
        }

        return string
    }
}

extension Headers : Equatable {}

public func == (lhs: Headers, rhs: Headers) -> Bool {
    return lhs.headers == rhs.headers
}
