import Foundation

class ConnectionWriteBuffer {
    private let transport: Transport

    init(transport: Transport) {
        self.transport = transport
    }

    func write(bytes: [UInt8]) throws {
        try self.transport.write(bytes: bytes)
    }
}

extension ConnectionWriteBuffer {
    func write(value: Data) throws {
        try value.withUnsafeBytes {
            try self.write(bytes: [UInt8](UnsafeBufferPointer(start: $0, count: value.count)))
        }
    }

    func write(value: String, encoding: String.Encoding = .utf8) throws {
        guard let data = value.data(using: encoding, allowLossyConversion: false) else {
            throw Error(code: .encoding, reason: "Could not encode string.")
        }
        return try self.write(value: data)
    }

    func write(value: JSON) throws {
        try self.write(bytes: [UInt8](try JSON.Serializer.serialize(value).utf8))
    }

    func write(value: Int8) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: Int16) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: Int32) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: Int64) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: Int) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: UInt8) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: UInt16) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: UInt32) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: UInt64) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    func write(value: UInt) throws {
        try self.writeIntegerPrimitive(value: value)
    }

    private func writeIntegerPrimitive<T>(value: T) throws {
        let length = MemoryLayout.size(ofValue: value)
        try [value].withUnsafeBufferPointer { body in
            try body.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: length) {
                try self.write(bytes: [UInt8](UnsafeBufferPointer(start: $0, count: length)))
            }
        }
    }

}

class ConnectionReadBuffer {
    private let transport: Transport

    private var data: [UInt8] = []

    init(transport: Transport) {
        self.transport = transport
    }

    func unread(_ data: [UInt8]) {
        self.data = data + self.data
    }

    func read(length: Int) throws -> [UInt8] {
        try self.fill(length: length)
        return try self.drain(length: length)
    }

    func readToNullTerminator(maxLength: Int) throws -> [UInt8] {
        var nullTerminatorOffset: Int? = nil
        while nullTerminatorOffset == nil {
            // look for null terminator
            for i in 0..<self.data.count {
                guard self.data[i] == 0 else {
                    continue
                }
                nullTerminatorOffset = i
                break
            }

            // guard we're not done or overflowed
            guard nullTerminatorOffset == nil, self.data.count < maxLength else {
                break
            }

            // fill more data
            try self.fill(maxLength: maxLength - self.data.count)
        }

        // guard we have an offset otherwise we overflowed
        guard let offset = nullTerminatorOffset else {
            throw Error(code: .connection, reason: "Failed to read to null terminator after \(maxLength) bytes.", underlyingError: nil)
        }

        return try self.drain(length: offset + 1)
    }

    func readToNullTerminatedJSON(maxLength: Int) throws -> JSON {
        let data = try self.readToNullTerminator(maxLength: maxLength)
        guard data.count > 1 else {
            throw Error(code: .decoding, reason: "Empty JSON.", underlyingError: nil)
        }

        do {
            return try JSON.Parser.parse([UInt8](data[0..<(data.count - 1)]))
        } catch {
            throw Error(code: .decoding, reason: "Failed to parse JSON.", underlyingError: error)
        }
    }

    private func drain(length: Int) throws -> [UInt8] {
        let drained: [UInt8]
        if self.data.count > length {
            drained = [UInt8](self.data[0..<length])
            self.data = [UInt8](self.data[length..<self.data.count])
        } else {
            drained = self.data
            self.data = []
        }
        return drained
    }

    private func fill(maxLength: Int) throws {
        self.data += try self.transport.read(maxBytes: maxLength)
    }

    private func fill(length: Int) throws {
        while self.data.count < length {
            self.data += try self.transport.read(maxBytes: length - self.data.count)
        }
    }
}

extension ConnectionReadBuffer {
    func read(length: Int) throws -> Data {
        return Data(bytes: try self.read(length: length))
    }

    func read(length: Int, encoding: String.Encoding = .utf8) throws -> String {
        let bytes: [UInt8] = try self.read(length: length)
        guard let string = String(bytes: bytes, encoding: encoding) else {
            throw Error(code: .decoding, reason: "Could not decode string.")
        }
        return string
    }

    func read(length: Int) throws -> JSON {
        return try JSON.Parser.parse(self.read(length: length))
    }

    func read() throws -> Int8 {
        return try self.readIntegerPrimitive(type: Int8.self)
    }

    func read() throws -> Int16 {
        return try self.readIntegerPrimitive(type: Int16.self)
    }

    func read() throws -> Int32 {
        return try self.readIntegerPrimitive(type: Int32.self)
    }

    func read() throws -> Int64 {
        return try self.readIntegerPrimitive(type: Int64.self)
    }

    func read() throws -> Int {
        return try self.readIntegerPrimitive(type: Int.self)
    }

    func read() throws -> UInt8 {
        return try self.readIntegerPrimitive(type: UInt8.self)
    }

    func read() throws -> UInt16 {
        return try self.readIntegerPrimitive(type: UInt16.self)
    }

    func read() throws -> UInt32 {
        return try self.readIntegerPrimitive(type: UInt32.self)
    }

    func read() throws -> UInt64 {
        return try self.readIntegerPrimitive(type: UInt64.self)
    }

    func read() throws -> UInt {
        return try self.readIntegerPrimitive(type: UInt.self)
    }

    private func readIntegerPrimitive<T>(type: T.Type) throws -> T {
        let length = MemoryLayout<T>.size
        let data: [UInt8] = try self.read(length: length)
        return UnsafePointer(data).withMemoryRebound(to: type, capacity: 1) { $0.pointee }
    }
}
