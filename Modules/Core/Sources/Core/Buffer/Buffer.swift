@_exported import struct Dispatch.DispatchData

public typealias Byte = UInt8
public typealias Buffer = DispatchData

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
        self = [UInt8](string.utf8).withUnsafeBufferPointer { Buffer(bytes: $0) }
    }
    public init(_ bytes: [UInt8]) {
        self = bytes.withUnsafeBufferPointer { Buffer(bytes: $0) }
    }
    public init() {
        self = Buffer.empty
    }
}

extension String : BufferConvertible {
    public init(buffer: Buffer) throws {
        guard let string = String(bytes: buffer, encoding: .utf8) else {
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

extension Buffer: Equatable {    
}

public func ==(lhs: Buffer, rhs: Buffer) -> Bool {
    return lhs.hexadecimalString() == rhs.hexadecimalString()
}
