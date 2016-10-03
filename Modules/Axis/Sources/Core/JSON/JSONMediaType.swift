public enum JSON {}

extension JSON : MediaTypeRepresentor {
    public static var mediaType: MediaType {
        return MediaType(
            type: "application",
            subtype: "json",
            parameters: ["charset": "utf-8"]
        )
    }

    public static var parser: MapParser {
        return JSONMapParser()
    }

    public static var serializer: MapSerializer {
        return JSONMapSerializer()
    }
}
