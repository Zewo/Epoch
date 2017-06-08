#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import Venice
import Core
import CLibdill
import CBtls

// TODO: Create TCP errors
public enum TLSError : Error {}

public final class TLSHost : Host {
    private typealias Handle = Int32
    private typealias Socket = Int32

    private let handle: Handle
    private let socket: Socket
    public let ip: IP
    
    private init(handle: Handle, socket: Socket, ip: IP) {
        self.handle = handle
        self.socket = socket
        self.ip = ip
    }
    
    deinit {
        hclose(handle)
    }
    
    public convenience init(
        ip: IP,
        certificatePath: String,
        keyPath: String,
        backlog: Int,
        reusePort: Bool
    ) throws {
        var address = ip.address
        var result = tcp_listen(&address, Int32(backlog))
        
        // TODO: Set reusePort
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        let socket = result
        var keyPair = btls_kp()
        var certificateLength = 0
        var keyLength = 0
        
        guard let certificate = btls_loadfile(certificatePath, &certificateLength, nil) else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        guard let key = btls_loadfile(keyPath, &keyLength, nil) else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        result = btls_kp(&keyPair, certificate, certificateLength, key, keyLength)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        result = btls_attach_server(socket, UInt64(BTLS_DEFAULT), 0, &keyPair, 1, nil, nil)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        // TODO: deallocate this in deinit
//        certificate.deallocate(capacity: 1)
//        key.deallocate(capacity: 1)
        
        self.init(handle: result, socket: socket, ip: ip)
    }
    
    public convenience init(
        host: String = "",
        port: Int = 8080,
        certificatePath: String,
        keyPath: String,
        backlog: Int = 128,
        reusePort: Bool = false
    ) throws {
        let ip: IP
        
        if host == "" {
            ip = try IP(port: port)
        } else {
            ip = try IP(local: host, port: port)
        }
        
        try self.init(
            ip: ip,
            certificatePath: certificatePath,
            keyPath: keyPath,
            backlog: backlog,
            reusePort: reusePort
        )
    }
    
    public func accept(deadline: Deadline) throws -> DuplexStream {
        var address = ipaddr()
        var result = tcp_accept(self.socket, &address, deadline.value)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        let socket = result
        result = btls_attach_accept(socket, handle)
        
        guard result != -1 else {
            switch errno {
            default:
                throw SystemError.lastOperationError
            }
        }
        
        return TLSStream(handle: result, socket: socket, ip: IP(address: &address), open: true)
    }
}
