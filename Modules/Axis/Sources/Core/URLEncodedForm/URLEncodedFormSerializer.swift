enum URLEncodedFormSerializeError : Error {
    case invalidMap
}

public struct URLEncodedFormSerializer {
    public init() {}

    public func serialize(_ urlEncodedForm: URLEncodedForm) -> Data {
        return serializeToString(urlEncodedForm).data
    }

    public func serializeToString(_ urlEncodedForm: URLEncodedForm) -> String {
        var string = ""

        for (offset: index, element: (key: key, value: value)) in urlEncodedForm.values.enumerated() {
            if index != 0 {
                string += "&"
            }

            string += "\(key)=\(value)"
        }

        return string
    }
}
