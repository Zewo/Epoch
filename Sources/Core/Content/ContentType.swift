public struct ContentType {
    public let mediaType: MediaType
    public let parser: ContentParser.Type
    public let serializer: ContentSerializer.Type
    
    public init(
        mediaType: MediaType,
        parser: ContentParser.Type,
        serializer: ContentSerializer.Type
    ) {
        self.mediaType = mediaType
        self.parser = parser
        self.serializer = serializer
    }
}
