import Axis

#if os(Linux)
    import Glibc
#else
    import Security
#endif

extension Buffer {
    public mutating func append(_ byte: UInt8) {
        var byte = byte
        self.append(&byte, count: 1)
    }

    public mutating func append(_ bytes: [UInt8]) {
        self.append(bytes, count: bytes.count)
    }

    init<T: Integer>(number: T) {
        let totalBytes = MemoryLayout<T>.size

        let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        valuePointer.pointee = number
        defer {
            valuePointer.deinitialize()
            valuePointer.deallocate(capacity: 1)
        }

        var bytes = [UInt8](repeating: 0, count: totalBytes)
        self = valuePointer.withMemoryRebound(to: UInt8.self, capacity: totalBytes) { p in
            for i in 0..<totalBytes {
                bytes[totalBytes - 1 - i] = (p + i).pointee
            }
            return Buffer(UnsafeBufferPointer(start: bytes, count: totalBytes))
        }
    }

    func toInt(_ size: Int, offset: Int = 0) -> UIntMax {
        guard size > 0 && size <= 8 && count >= offset+size else { return 0 }
        let slice = self[offset..<offset+size]
        var result: UIntMax = 0
        for (idx, byte) in slice.enumerated() {
            let shiftAmount = UIntMax(size.toIntMax() - idx - 1) * 8
            result += UIntMax(byte) << shiftAmount
        }
        return result
    }

    init(randomBytes byteCount: Int) throws {
        var bytes = [UInt8](repeating: 0, count: byteCount)

        #if os(Linux)
            let urandom = open("/dev/urandom", O_RDONLY)

            if urandom == -1 {
                try ensureLastOperationSucceeded()
            }

            if read(urandom, &bytes, bytes.count) == -1 {
                try ensureLastOperationSucceeded()
            }

            if close(urandom) == -1 {
                try ensureLastOperationSucceeded()
            }
        #else
            if SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes) == -1 {
                try ensureLastOperationSucceeded()
            }
        #endif

        self.init(bytes)
    }
}
