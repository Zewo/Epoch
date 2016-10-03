extension URLEncodedForm : MediaTypeRepresentor {
    public static var mediaType: MediaType {
        return MediaType(
            type: "application",
            subtype: "x-www-form-urlencoded",
            parameters: ["charset": "utf-8"]
        )
    }

    public static var parser: MapParser {
        return URLEncodedFormMapParser()
    }

    public static var serializer: MapSerializer {
        return URLEncodedFormMapSerializer()
    }
}
