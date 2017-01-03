import CLibdill

public struct ChannelIterator<T> : IteratorProtocol {
    let channel: Channel<T>

    public mutating func next() -> ChannelResult<T>? {
        return try? channel.receiveResult()
    }
}

public final class Channel<T> : Handle, Sequence {
    static var length: Int {
        return MemoryLayout<ChannelResult<T>>.stride
    }

    var buffer: [ChannelResult<T>] = []

//    public init() throws {
//        let result = chmake(Channel.length)
//
//        guard result != -1 else {
//            switch errno {
//            case ECANCELED:
//                throw VeniceError.canceled
//            case ENOMEM:
//                throw VeniceError.outOfMemory
//            default:
//                throw VeniceError.unexpected
//            }
//        }
//
//        super.init(handle: result)
//    }

    public init() throws {
        let result = chmake(0)

        guard result != -1 else {
            switch errno {
            case ECANCELED:
                throw VeniceError.canceled
            case ENOMEM:
                throw VeniceError.outOfMemory
            default:
                throw VeniceError.unexpected
            }
        }

        super.init(handle: result)
    }

    /// Reference that can only send values.
    public lazy var sending: SendingChannel<T> = SendingChannel(self)

    /// Reference that can only receive values.
    public lazy var receiving: ReceivingChannel<T> = ReceivingChannel(self)

    /// Creates a generator.
    public func makeIterator() -> ChannelIterator<T> {
        return ChannelIterator(channel: self)
    }

    /// Mark the channel as done. When a channel is marked as done it cannot receive or send values anymore.
    public func done() throws {
        let result = chdone(handle)

        guard result == 0 else {
            switch errno {
            case EBADF:
                throw VeniceError.invalidHandle
            case EPIPE:
                throw VeniceError.channelIsDone
            default:
                throw VeniceError.unexpected
            }
        }
    }

    /// Send a value to the channel.
    public func send(_ value: T, deadline: Deadline = .never) throws {
        try send(.value(value), deadline: deadline)
    }

    /// Send an error to the channel.
    public func send(_ error: Error, deadline: Deadline = .never) throws {
        try send(.error(error), deadline: deadline)
    }

//    public func send(_ channelResult: inout ChannelResult<T>, deadline: Deadline = .never) throws {
//        let result = chsend(handle, nil, 0, deadline)
//
//        guard result == 0 else {
//            switch errno {
//            case EBADF:
//                throw VeniceError.invalidHandle
//            case ECANCELED:
//                throw VeniceError.canceled
//            case EPIPE:
//                throw VeniceError.channelIsDone
//            case ETIMEDOUT:
//                throw VeniceError.timeout
//            default:
//                throw VeniceError.unexpected
//            }
//        }
//    }

    /// Receive a value from channel.
    @discardableResult
    public func receive(deadline: Deadline = .never) throws -> T {
        switch try receiveResult(deadline: deadline) {
        case .value(let value):
            return value
        case .error(let error):
            throw error
        }
    }

//    /// Receive a result from channel.
//    @discardableResult
//    public func receiveResult(deadline: Deadline = .never) throws -> ChannelResult<T> {
//        var channelResult = ChannelResult<T>.error(VeniceError.unexpected)
//
//        let result = withUnsafeMutablePointer(to: &channelResult) { value in
//            chrecv(handle, value, Channel.length, deadline)
//        }
//
//        guard result == 0 else {
//            switch errno {
//            case EBADF:
//                throw VeniceError.invalidHandle
//            case ECANCELED:
//                throw VeniceError.canceled
//            case EPIPE:
//                throw VeniceError.channelIsDone
//            case ETIMEDOUT:
//                throw VeniceError.timeout
//            default:
//                throw VeniceError.unexpected
//            }
//        }
//
//        return channelResult
//    }

    public func send(_ channelResult: ChannelResult<T>, deadline: Deadline = .never) throws {
        buffer.append(channelResult)
        let result = chsend(handle, nil, 0, deadline)

        guard result == 0 else {
            _ = buffer.popLast()

            switch errno {
            case EBADF:
                throw VeniceError.invalidHandle
            case ECANCELED:
                throw VeniceError.canceled
            case EPIPE:
                throw VeniceError.channelIsDone
            case ETIMEDOUT:
                throw VeniceError.timeout
            default:
                throw VeniceError.unexpected
            }
        }
    }

    /// Receive a result from channel.
    @discardableResult
    public func receiveResult(deadline: Deadline = .never) throws -> ChannelResult<T> {
        let result = chrecv(handle, nil, 0, deadline)

        guard result == 0 else {
            switch errno {
            case EBADF:
                throw VeniceError.invalidHandle
            case ECANCELED:
                throw VeniceError.canceled
            case EPIPE:
                throw VeniceError.channelIsDone
            case ETIMEDOUT:
                throw VeniceError.timeout
            default:
                throw VeniceError.unexpected
            }
        }

        return buffer.removeFirst()
    }
}
