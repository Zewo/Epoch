// This file has been modified from its original project Swift-JsonSerializer

public final class JSONMapParser : MapParser {
    public init() {}

    @discardableResult public func parse(_ buffer: UnsafeBufferPointer<Byte>) throws -> Map? {
        struct TempError : Error {}
        throw TempError()
    }
}
