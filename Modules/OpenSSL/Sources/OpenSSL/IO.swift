import COpenSSL
import Core

public enum SSLIOError: Error {
    case io(description: String)
    case shouldRetry(description: String)
    case unsupportedMethod(description: String)
}

public class IO {
	public enum Method {
		case memory

		var method: UnsafeMutablePointer<BIO_METHOD> {
			switch self {
			case .memory:
				return BIO_s_mem()
			}
		}
	}

	var bio: UnsafeMutablePointer<BIO>?

	public init(method: Method = .memory) throws {
		initialize()
		bio = BIO_new(method.method)

		if bio == nil {
			throw SSLIOError.io(description: lastSSLErrorDescription)
		}
	}

	public convenience init(buffer: BufferRepresentable) throws {
		try self.init()
        _ = try buffer.buffer.bytes.withUnsafeBufferPointer {
            try write($0)
        }
        
	}

	// TODO: crash???
//	deinit {
//		BIO_free(bio)
//	}

	public var pending: Int {
		return BIO_ctrl_pending(bio)
	}

	public var shouldRetry: Bool {
		return (bio!.pointee.flags & BIO_FLAGS_SHOULD_RETRY) != 0
	}
    
    public func write(_ buffer: UnsafeBufferPointer<UInt8>) throws -> Int {
        guard !buffer.isEmpty else {
            return 0
        }
        
        let bytesWritten = BIO_write(bio, buffer.baseAddress!, Int32(buffer.count))
        
        guard bytesWritten >= 0 else {
            if shouldRetry {
                throw SSLIOError.shouldRetry(description: lastSSLErrorDescription)
            } else {
                throw SSLIOError.io(description: lastSSLErrorDescription)
            }
        }
        
        return Int(bytesWritten)
    }
    
    public func read(into: UnsafeMutableBufferPointer<UInt8>) throws -> Int {
        guard !into.isEmpty else {
            return 0
        }
        
        let bytesRead = BIO_read(bio, into.baseAddress!, Int32(into.count))
        
        guard bytesRead >= 0 else {
            if shouldRetry {
                throw SSLIOError.shouldRetry(description: lastSSLErrorDescription)
            } else {
                throw SSLIOError.io(description: lastSSLErrorDescription)
            }
        }
        
        return Int(bytesRead)
    }
}
