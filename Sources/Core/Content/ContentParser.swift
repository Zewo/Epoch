import Venice

public enum ContentParserError : Error {
    case invalidInput
}

public protocol ContentParser {
    init()
    @discardableResult func parse(_ buffer: UnsafeRawBufferPointer) throws -> Content?
}

extension ContentParser {
    public func finish() throws -> Content {
        let empty = UnsafeRawBufferPointer(start: nil, count: 0)
        
        guard let map = try self.parse(empty) else {
            throw ContentParserError.invalidInput
        }
        
        return map
    }
    
    public static func parse(_ buffer: UnsafeRawBufferPointer) throws -> Content {
        let parser = self.init()
        
        if let map = try parser.parse(buffer) {
            return map
        }
        
        return try parser.finish()
    }
    
    public static func parse(
        _ stream: ReadableStream,
        bufferSize: Int = 4096,
        deadline: Deadline
    ) throws -> Content {
        let parser = self.init()
        let buffer = UnsafeMutableRawBufferPointer.allocate(count: bufferSize)
        defer { buffer.deallocate() }
        
        while true {
            let readBuffer = try stream.read(into: buffer, deadline: deadline)
            
            if let result = try parser.parse(readBuffer) {
                return result
            }
        }
    }
}
