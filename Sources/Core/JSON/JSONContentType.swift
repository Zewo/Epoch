extension ContentType {
    public static let json = ContentType(
        mediaType: .json,
        parser: JSONParser.self,
        serializer: JSONSerializer.self
    )
}
