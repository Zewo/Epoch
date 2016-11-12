public enum MapParserError : Error {
    case invalidInput
}

public protocol MapParser {
    init()

    /// Use `parse` for incremental parsing. `parse` should be called
    /// many times with partial chunks of the source data. Send an empty buffer
    /// to signal you don't have any more chunks to send.
    ///
    /// The following example shows how you can implement incremental parsing:
    ///
    ///     let parser = JSONParser()
    ///
    ///     while true {
    ///         let buffer = try stream.read(upTo: bufferSize)
    ///         if let json = try parser.parse(buffer) {
    ///             return json
    ///         }
    ///     }
    ///
    /// - parameter buffer: `UnsafeBufferPointer` that points to the chunk
    ///   used to update the state of the parser.
    ///
    /// - throws: Throws when `buffer` is an invalid input for the given parser.
    ///
    /// - returns: Returns `nil` if the parser was not able to produce a result yet.
    ///   Otherwise returns the parsed value.
    @discardableResult func parse(_ buffer: UnsafeBufferPointer<Byte>) throws -> Map?
    @discardableResult func parse(_ buffer: BufferRepresentable) throws -> Map?
    func finish() throws -> Map
    static func parse(_ buffer: UnsafeBufferPointer<Byte>) throws -> Map
    static func parse(_ buffer: BufferRepresentable) throws -> Map
    static func parse(_ stream: InputStream, bufferSize: Int, deadline: Double) throws -> Map
}

extension MapParser {
    public func finish() throws -> Map {
        guard let map = try self.parse(UnsafeBufferPointer()) else {
            throw MapParserError.invalidInput
        }
        return map
    }

    public func parse(_ buffer: BufferRepresentable) throws -> Map? {
        return try buffer.buffer.withUnsafeBufferPointer({ try parse($0) })
    }

    public static func parse(_ buffer: UnsafeBufferPointer<Byte>) throws -> Map {
        let parser = self.init()

        if let map = try parser.parse(buffer) {
            return map
        }

        return try parser.finish()
    }

    public static func parse(_ buffer: BufferRepresentable) throws -> Map {
        return try buffer.buffer.withUnsafeBufferPointer({ try parse($0) })
    }

    public static func parse(_ stream: InputStream, bufferSize: Int = 4096, deadline: Double) throws -> Map {
        let parser = self.init()
        let buffer = UnsafeMutableBufferPointer<Byte>(capacity: bufferSize)
        defer { buffer.deallocate(capacity: bufferSize) }

        while true {
            let readBuffer = try stream.read(into: buffer, deadline: deadline)
            if let result = try parser.parse(readBuffer) {
                return result
            }
        }
    }
}
