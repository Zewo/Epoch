#if os(Linux)
    import Glibc
#else
    import Darwin
#endif

public typealias Byte = UInt8

public struct Buffer : RandomAccessCollection {
    public typealias Iterator = Array<Byte>.Iterator
    public typealias Index = Int
    public typealias Indices = DefaultRandomAccessIndices<Buffer>
    
    public private(set) var bytes: [Byte]
    
    public var count: Int {
        return bytes.count
    }
    
    public init(_ bytes: [Byte] = []) {
        self.bytes = bytes
    }

    public init(_ bytes: ArraySlice<Byte>) {
        self.bytes = [Byte](bytes)
    }
    
    public init(_ bytes: UnsafeBufferPointer<Byte>) {
        self.bytes = [Byte](bytes)
    }
    
    public mutating func append(_ other: Buffer) {
        bytes.append(contentsOf: other.bytes)
    }
    
    public mutating func append(_ other: [Byte]) {
        bytes.append(contentsOf: other)
    }
    
    public mutating func append(_ other: UnsafeBufferPointer<Byte>) {
        guard other.count > 0 else {
            return
        }
        bytes.append(contentsOf: [Byte](other))
    }
    
    public mutating func append(_ other: UnsafePointer<Byte>, count: Int) {
        guard count > 0 else {
            return
        }
        bytes.append(contentsOf: [Byte](UnsafeBufferPointer(start: other, count: count)))
    }
    
    public subscript(index: Index) -> Byte {
        return bytes[index]
    }
    
    public subscript(bounds: Range<Int>) -> Buffer {
        return Buffer(bytes[bounds])
    }
    
    public subscript(bounds: CountableRange<Int>) -> Buffer {
        return Buffer(bytes[bounds])
    }
    
    public var startIndex: Int {
        return 0
    }
    
    public var endIndex: Int {
        return count
    }
    
    public func index(before i: Int) -> Int {
        return i - 1
    }
    
    public func index(after i: Int) -> Int {
        return i + 1
    }
    
    public func makeIterator() -> Iterator {
        return bytes.makeIterator()
    }
    
    public func copyBytes(to pointer: UnsafeMutablePointer<Byte>, count: Int) {
        copyBytes(to: UnsafeMutableBufferPointer(start: pointer, count: count))
    }
    
    public func copyBytes(to pointer: UnsafeMutableBufferPointer<Byte>) {
        guard pointer.count > 0 else {
            return
        }
        
        precondition(bytes.endIndex >= 0)
        precondition(bytes.endIndex <= pointer.count, "The pointer is not large enough")
        
        _ = bytes.withUnsafeBufferPointer {
            memcpy(pointer.baseAddress!, $0.baseAddress!, count)
        }
        
    }
    
    public func withUnsafeBytes<Result, ContentType>(body: (UnsafePointer<ContentType>) throws -> Result) rethrows -> Result {
        return try bytes.withUnsafeBufferPointer {
            let capacity = count / MemoryLayout<ContentType>.stride
            return try $0.baseAddress!.withMemoryRebound(to: ContentType.self, capacity: capacity) { try body($0) }
        }
        
    }

    public func withUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeBufferPointer(body)
    }

    public mutating func withUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Byte>) throws -> R) rethrows -> R {
        return try bytes.withUnsafeMutableBufferPointer(body)
    }
}

extension Buffer {
    public static var empty: Buffer {
        return Buffer()
    }
}

extension UnsafeBufferPointer {
    public init() {
        self.init(start: nil, count: 0)
    }
}

extension UnsafeMutableBufferPointer {
    public init() {
        self.init(start: nil, count: 0)
    }

    public init(capacity: Int) {
        let pointer = UnsafeMutablePointer<Element>.allocate(capacity: capacity)
        self.init(start: pointer, count: capacity)
    }

    public func deallocate(capacity: Int) {
        baseAddress?.deallocate(capacity: capacity)
    }
}

public protocol BufferInitializable {
    init(buffer: Buffer) throws
}

public protocol BufferRepresentable {
    var buffer: Buffer { get }
}

extension Buffer : BufferRepresentable {
    public var buffer: Buffer {
        return self
    }
}

public protocol BufferConvertible : BufferInitializable, BufferRepresentable {}

extension Buffer {
    public init(_ string: String) {
        self = Buffer([Byte](string.utf8))
    }
    
    public init(count: Int, fill: (UnsafeMutableBufferPointer<Byte>) throws -> Void) rethrows {
        self = try Buffer(capacity: count) {
            guard count > 0 else {
                return 0
            }
            try fill($0)
            return count
        }
    }

    
    public init(capacity: Int, fill: (UnsafeMutableBufferPointer<Byte>) throws -> Int) rethrows {
        var bytes = [Byte](repeating: 0, count: capacity)
        let usedCapacity = try bytes.withUnsafeMutableBufferPointer { try fill($0) }

        guard usedCapacity > 0 else {
            self = Buffer()
            return
        }

        
        self = Buffer([Byte](bytes.prefix(usedCapacity)))
    }
}

extension String : BufferConvertible {
    public init(buffer: Buffer) throws {
        guard let string = String(bytes: buffer.bytes, encoding: .utf8) else {
            throw StringError.invalidString
        }
        self = string
    }

    public var buffer: Buffer {
        return Buffer(self)
    }
}

extension Buffer {
    public func hexadecimalString(inGroupsOf characterCount: Int = 0) -> String {
        var string = ""
        for (index, value) in self.enumerated() {
            if characterCount != 0 && index > 0 && index % characterCount == 0 {
                string += " "
            }
            string += (value < 16 ? "0" : "") + String(value, radix: 16)
        }
        return string
    }

    public var hexadecimalDescription: String {
        return hexadecimalString(inGroupsOf: 2)
    }
}

extension Buffer : CustomDebugStringConvertible {
    public var debugDescription: String {
        return (try? String(buffer: self)) ?? hexadecimalString()
    }
}

extension Buffer : Equatable {}

public func ==(lhs: Buffer, rhs: Buffer) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    guard lhs.count > 0 && rhs.count > 0 else {
        return true
    }

    return lhs.bytes == rhs.bytes
}
