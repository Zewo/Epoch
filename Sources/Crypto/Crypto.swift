import Core
import CArgon2
import CLibtls

public struct Crypto {
    public static func hs256(
        _ string: String,
        key: UnsafeRawBufferPointer,
        buffer: UnsafeMutableRawBufferPointer
    ) -> UnsafeRawBufferPointer {
        guard buffer.count >= Int(EVP_MAX_MD_SIZE) else {
            // invalid buffer size
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        var bufferCount: UInt32 = 0
        
        let result = string.withCString {
            HMAC(
                EVP_sha256(),
                key.baseAddress,
                Int32(key.count),
                UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self),
                string.utf8.count,
                buffer.baseAddress?.assumingMemoryBound(to: UInt8.self),
                &bufferCount
            )
        }
        
        guard result != nil else {
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        return UnsafeRawBufferPointer(buffer.prefix(upTo: Int(bufferCount)))
    }

    public static func hs256(
        _ string: String,
        key: BufferRepresentable,
        buffer: UnsafeMutableRawBufferPointer
    ) -> UnsafeRawBufferPointer {
        return key.withBuffer {
            hs256(string, key: $0, buffer: buffer)
        }
    }

    public static func hs256<B : BufferInitializable>(
        _ string: String,
        key: BufferRepresentable
    ) -> B {
        let buffer = UnsafeMutableRawBufferPointer.allocate(count: Int(EVP_MAX_MD_SIZE))
        
        defer {
            buffer.deallocate()
        }
        
        return B(hs256(string, key: key, buffer: buffer))
    }

    public static func sha256(
        _ string: String,
        buffer: UnsafeMutableRawBufferPointer
    ) -> UnsafeRawBufferPointer {
        guard buffer.count >= Int(SHA256_DIGEST_LENGTH) else {
            // invalid buffer size
            return UnsafeRawBufferPointer(start: nil, count: 0)
        }
        
        var sha256 = SHA256_CTX()
        SHA256_Init(&sha256)
        
        _ = string.withCString {
            SHA256_Update(&sha256, $0, string.utf8.count)
        }
        
        SHA256_Final(buffer.baseAddress?.assumingMemoryBound(to: UInt8.self), &sha256)
        
        return UnsafeRawBufferPointer(buffer.prefix(Int(SHA256_DIGEST_LENGTH)))
    }

    public static func sha256<B : BufferInitializable>(_ string: String) -> B  {
        let buffer = UnsafeMutableRawBufferPointer.allocate(count: Int(SHA256_DIGEST_LENGTH))
        
        defer {
            buffer.deallocate()
        }
        
        return B(sha256(string, buffer: buffer))
    }
    
    public static func argon2(password: String, salt: String) -> String {
        var encoded = [Int8](repeating: 0, count: 108)
        
        let result = encoded.withUnsafeMutableBufferPointer { encoded in
            password.withCString { passwordPointer in
                salt.withCString { saltPointer in
                    argon2i_hash_encoded(
                        2,
                        65536,
                        1,
                        UnsafeRawPointer(passwordPointer),
                        password.utf8.count,
                        saltPointer,
                        salt.utf8.count,
                        32,
                        encoded.baseAddress,
                        encoded.count
                    )
                }
            }
        }
        
        guard result == ARGON2_OK.rawValue else {
            return String(cString: argon2_error_message(result))
        }
        
        return String(cString: encoded + [0])
    }
    
    public static func base64Encode(
        input: UnsafeRawBufferPointer,
        buffer: UnsafeMutableRawBufferPointer
    ) {
        let b64 = BIO_new(BIO_f_base64())
        let bio = BIO_new(BIO_s_mem())
        
        defer {
            BIO_free(b64)
        }
        
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL)
        BIO_push(b64, bio)
        
        var result = BIO_write(b64, input.baseAddress, Int32(input.count))
        BIO_ctrl(b64, BIO_CTRL_FLUSH, 0, nil)
        
        guard result > 0 else {
            // throw error
            return
        }
        
        result = BIO_read(bio, buffer.baseAddress, Int32(buffer.count))
        
        guard result > 0 else {
            // throw error
            return
        }
    }

    public static func base64Decode(
        input: UnsafeRawBufferPointer,
        buffer: UnsafeMutableRawBufferPointer
    ) {
        let b64 = BIO_new(BIO_f_base64())
        let bio = BIO_new(BIO_s_mem())
        
        defer {
            BIO_free(b64)
        }
        
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL)
        BIO_push(b64, bio)
        
        var result = BIO_write(bio, input.baseAddress, Int32(input.count))
        BIO_ctrl(bio, BIO_CTRL_FLUSH, 0, nil)
        
        guard result > 0 else {
            // throw error
            return
        }
        
        result = BIO_read(b64, buffer.baseAddress, Int32(buffer.count))
        
        guard result > 0 else {
            // throw error
            return
        }
    }
}
