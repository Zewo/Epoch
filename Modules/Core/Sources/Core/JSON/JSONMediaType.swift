public enum JSON {}

extension JSON : MediaTypeConverter {
    public static var mediaType: MediaType {
        return MediaType(type: "application", subtype: "json", parameters: ["charset": "utf-8"])
    }

    public static var parser: MapParser.Type {
        return JSONMapParser.self
    }

    public static var serializer: MapSerializer.Type {
        return JSONMapSerializer.self
    }
}
