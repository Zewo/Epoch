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


extension ContentType: Hashable {
    
    public static func ==(lhs: ContentType, rhs: ContentType) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }

    public var hashValue: Int {
        return mediaType.hashValue
    }
}
