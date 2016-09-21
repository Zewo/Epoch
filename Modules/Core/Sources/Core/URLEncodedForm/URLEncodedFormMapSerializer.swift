enum URLEncodedFormMapSerializerError : Error {
    case invalidMap
}

public struct URLEncodedFormMapSerializer : MapSerializer {
    public init() {}

    public func serialize(_ map: Map) throws -> Buffer {
        return try serializeToString(map).buffer
    }

    public func serializeToString(_ map: Map) throws -> String {
        switch map {
        case .dictionary(let dictionary): return try serializeDictionary(dictionary)
        default: throw URLEncodedFormMapSerializerError.invalidMap
        }
    }

    func serializeDictionary(_ object: [String: Map]) throws -> String {
        var string = ""

        for (offset: index, element: (key: key, value: map)) in object.enumerated() {
            if index != 0 {
                string += "&"
            }
            string += String(key) + "="
            let value = try map.asString(converting: true)
            string += value.percentEncoded(allowing: .uriQueryAllowed)
        }

        return string
    }
}
