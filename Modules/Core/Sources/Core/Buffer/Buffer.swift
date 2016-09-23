@_exported import struct Dispatch.DispatchData
#if os(Linux)
import Glibc
#else
import Darwin
#endif

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
        self = string.utf8CString.withUnsafeBufferPointer { bufferPtr in
            guard bufferPtr.count > 1 else {
                return Buffer()
            }
            
            return bufferPtr.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: bufferPtr.count) { ptr in
                return Buffer(bytes: UnsafeBufferPointer<UInt8>(start: ptr, count: bufferPtr.count - 1))
            }
        }
    }
    
    public init(_ bytes: [UInt8]) {
        self = bytes.withUnsafeBufferPointer { Buffer(bytes: $0) }
    }
    
    public init() {
        self = Buffer.empty
    }
    
    public init(count: Int, fill: (UnsafeMutableBufferPointer<UInt8>) throws -> Void) rethrows {
        self = try Buffer(capacity: count) {
            try fill($0)
            return count
        }
    }
    
    public init(capacity: Int, fill: (UnsafeMutableBufferPointer<UInt8>) throws -> Int) rethrows {
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: capacity)
        let buffer = UnsafeMutableBufferPointer(start: bytes, count: capacity)
        let usedCapacity = try fill(buffer)
        
        guard usedCapacity > 0 else {
            bytes.deallocate(capacity: capacity)
            self = Buffer.empty
            return
        }
        
        guard Double(usedCapacity) > Double(capacity) * 0.25 else {
            defer {
                bytes.deallocate(capacity: capacity)
            }
            self = Buffer(bytes: UnsafeBufferPointer<UInt8>(start: bytes, count: usedCapacity))
            return
        }
        
        self = Buffer(bytesNoCopy: UnsafeBufferPointer<UInt8>(start: bytes, count: usedCapacity), deallocator: .free)
    }
    
    public subscript(_ range: Range<Int>) -> Buffer {
        return subdata(in: self.startIndex.advanced(by: range.lowerBound)..<self.startIndex.advanced(by: range.upperBound))
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

extension Buffer: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return (try? String(buffer: self)) ?? hexadecimalString()
    }
    
}

extension Buffer: Equatable {    
}


public func ==(lhs: Buffer, rhs: Buffer) -> Bool {
    guard lhs.count == rhs.count else {
        return false
    }
    guard lhs.count > 0 && rhs.count > 0 else {
        return true
    }
    
    return lhs.withUnsafeBytes { lhsBytes in
        rhs.withUnsafeBytes { rhsBytes in
            return memcmp(UnsafeRawPointer(lhsBytes), UnsafeRawPointer(rhsBytes), lhs.count) == 0
        }
    }
}
