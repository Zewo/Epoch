public final class ReceivingChannel<T> : Handle, Sequence {
    private let channel: Channel<T>

    init(_ channel: Channel<T>) {
        self.channel = channel
        super.init(handle: channel.handle)
    }
    
    public func makeIterator() -> ChannelIterator<T> {
        return ChannelIterator(channel: channel)
    }

    @discardableResult
    public func receive(deadline: Deadline = .never) throws -> T {
        return try channel.receive(deadline: deadline)
    }

    @discardableResult
    public func receiveResult(deadline: Deadline = .never) throws -> ChannelResult<T> {
        return try channel.receiveResult(deadline: deadline)
    }

    public func done() throws {
        try channel.done()
    }
}
