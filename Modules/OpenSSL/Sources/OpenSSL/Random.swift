#if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

import COpenSSL

public enum SSLRandomError: Error {
    case error(description: String)
}

public class Random {
    public static func number(max: Int = Int(UInt32.max)) -> Int {
        #if os(OSX) || os(iOS) || os(tvOS) || os(watchOS)
            return Int(arc4random_uniform(UInt32(max)))
        #elseif os(Linux)
            return Int(random() % (max + 1))
        #endif
    }
    
    public static func bytes(_ size: Int) throws -> Buffer {
        let pointer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        defer {
            pointer.deallocate(capacity: size)
        }
        guard RAND_bytes(pointer, Int32(size)) == 1 else {
            pointer.deallocate(capacity: size)
            throw SSLRandomError.error(description: lastSSLErrorDescription)
        }
        
        return Buffer(UnsafeBufferPointer(start: pointer, count: size))
    }
}
