extension MediaType {
    public static var urlEncodedForm: MediaType {
        return MediaType(type: "application", subtype: "x-www-form-urlencoded", parameters: ["charset": "utf-8"])
    }
}

extension MediaTypeConverter {
    public static var urlEncodedForm: MediaTypeConverter {
        return MediaTypeConverter(
            mediaType: .urlEncodedForm,
            parser: URLEncodedFormMapParser.self,
            serializer: URLEncodedFormMapSerializer.self
        )
    }
}
