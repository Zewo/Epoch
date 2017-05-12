public final class SendingChannel<T> : Handle {
    private let channel: Channel<T>

    init(_ channel: Channel<T>) {
        self.channel = channel
        super.init(handle: channel.handle)
    }

    public func send(_ value: T, deadline: Deadline = .never) throws {
        try channel.send(value, deadline: deadline)
    }

    public func send(_ error: Error, deadline: Deadline = .never) throws {
        try channel.send(error, deadline: deadline)
    }

    public func send(_ result: ChannelResult<T>, deadline: Deadline = .never) throws {
        try channel.send(result, deadline: deadline)
    }
    
    public func done() throws {
        try channel.done()
    }
}
