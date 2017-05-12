import CLibdill

public typealias HandleDescriptor = Int32

public class Handle {
    let handle: HandleDescriptor

    init(handle: HandleDescriptor) {
        self.handle = handle
    }

    deinit {
        try? close()
    }

    public func duplicate() throws -> Handle {
        let result = hdup(handle)

        guard result != -1 else {
            switch errno {
            case EBADF:
                throw VeniceError.invalidHandle
            default:
                throw VeniceError.unexpected
            }
        }

        return Handle(handle: result)
    }

    public func close() throws {
        let result = hclose(handle)

        guard result == 0 else {
            switch errno {
            case EBADF:
                throw VeniceError.invalidHandle
            default:
                throw VeniceError.unexpected
            }
        }
    }
}
