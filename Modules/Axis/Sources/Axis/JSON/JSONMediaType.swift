extension MediaType {
    public static var json: MediaType {
        return MediaType(type: "application", subtype: "json", parameters: ["charset": "utf-8"])
    }
}

extension MediaTypeConverter {
    public static var json: MediaTypeConverter {
        return MediaTypeConverter(
            mediaType: .json,
            parser: JSONMapParser.self,
            serializer: JSONMapSerializer.self
        )
    }
}
