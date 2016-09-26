// DataExtensions.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import Core

#if os(Linux)
    import Glibc
#else
    import Security
#endif

extension Buffer {
    init<T>(number: T) {
        let totalBytes = MemoryLayout<T>.size
        let valuePointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        valuePointer.pointee = number
      
        let bytes = valuePointer.withMemoryRebound(to: UInt8.self, capacity: totalBytes, { (p) -> [UInt8] in
          
          var bytes = [UInt8](repeating: 0, count: totalBytes)
          for j in 0 ..< totalBytes {
            bytes[totalBytes - 1 - j] = (p + j).pointee
          }
          return bytes
        })
                valuePointer.deinitialize()
        valuePointer.deallocate(capacity: 1)
        self.init(bytes)
    }

    func toInt(_ size: Int, offset: Int = 0) -> UIntMax {
        guard size > 0 && size <= 8 && count >= offset+size else { return 0 }
      let slice = self.subdata(in:startIndex.advanced(by: offset) ..< startIndex.advanced(by: offset+size))
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
