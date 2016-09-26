public enum URLEncodedForm {}

extension URLEncodedForm : MediaTypeConverter {
    public static var mediaType: MediaType {
        return MediaType(
            type: "application",
            subtype: "x-www-form-urlencoded",
            parameters: ["charset": "utf-8"]
        )
    }

    public static var parser: MapParser.Type {
        return URLEncodedFormMapParser.self
    }

    public static var serializer: MapSerializer.Type {
        return URLEncodedFormMapSerializer.self
    }
}
