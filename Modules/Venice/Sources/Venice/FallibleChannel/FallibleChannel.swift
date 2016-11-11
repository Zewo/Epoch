import CLibvenice

public struct FallibleChannelGenerator<T> : IteratorProtocol {
    internal let channel: FallibleReceivingChannel<T>

    public mutating func next() -> ChannelResult<T>? {
        return channel.receiveResult()
    }
}

public enum ChannelResult<T> {
    case value(T)
    case error(Error)

    public func success(_ closure: (T) -> Void) {
        switch self {
        case .value(let value): closure(value)
        default: break
        }
    }

    public func failure(_ closure: (Error) -> Void) {
        switch self {
        case .error(let error): closure(error)
        default: break
        }
    }
}

public final class FallibleChannel<T> : Sequence {
    private let channel: chan
    public var closed: Bool = false
    private var buffer: [ChannelResult<T>] = []
    public let  bufferSize: Int

    public convenience init() {
        self.init(bufferSize: 0)
    }

    public init(bufferSize: Int) {
        self.bufferSize = bufferSize
        self.channel = mill_chmake_(bufferSize, "FallibleChannel init")
    }

    deinit {
        mill_chclose_(channel, "FallibleChannel deinit")
    }

    /// Reference that can only send values.
    public lazy var sendingChannel: FallibleSendingChannel<T> = FallibleSendingChannel(self)

    /// Reference that can only receive values.
    public lazy var receivingChannel: FallibleReceivingChannel<T> = FallibleReceivingChannel(self)

    /// Creates a generator.
    public func makeIterator() -> FallibleChannelGenerator<T> {
        return FallibleChannelGenerator(channel: receivingChannel)
    }

    /// Closes the channel. When a channel is closed it cannot receive values anymore.
    public func close() {
        guard !closed else { return }

        closed = true
        mill_chdone_(channel, "Channel close")
    }

    /// Send a result to the channel.
    public func send(_ result: ChannelResult<T>) {
        if !closed {
            buffer.append(result)
            mill_chs_(channel, "FallibleChannel sendResult")
        }
    }

    /// Send a value to the channel.
    public func send(_ value: T) {
        if !closed {
            let result = ChannelResult<T>.value(value)
            buffer.append(result)
            mill_chs_(channel, "FallibleChannel send")
        }
    }

    func send(_ value: T, clause: UnsafeMutableRawPointer, index: Int) {
        if !closed {
            let result = ChannelResult<T>.value(value)
            buffer.append(result)
            mill_choose_out_(clause, channel, Int32(index))
        }
    }

    /// Send an error to the channel.
    public func send(_ error: Error) {
        if !closed {
            let result = ChannelResult<T>.error(error)
            buffer.append(result)
            mill_chs_(channel, "FallibleChannel send")
        }
    }

    func send(_ error: Error, clause: UnsafeMutableRawPointer, index: Int) {
        if !closed {
            let result = ChannelResult<T>.error(error)
            buffer.append(result)
            mill_choose_out_(clause, channel, Int32(index))
        }
    }

    /// Receive a value from channel.
    @discardableResult
    public func receive() throws -> T? {
        if closed && buffer.isEmpty {
            return nil
        }
        mill_chr_(channel, "FallibleChannel receive")
        if let value = getResultFromBuffer() {
            switch value {
            case .value(let v): return v
            case .error(let e): throw e
            }
        } else {
            return nil
        }
    }

    /// Receive a result from channel.
    @discardableResult
    public func receiveResult() -> ChannelResult<T>? {
        if closed && buffer.isEmpty {
            return nil
        }
        mill_chr_(channel, "FallibleChannel receiveResult")
        return getResultFromBuffer()
    }

    func registerReceive(_ clause: UnsafeMutableRawPointer, index: Int) {
        mill_choose_in_(clause, channel, Int32(index))
    }

    func getResultFromBuffer() -> ChannelResult<T>? {
        if closed && buffer.isEmpty {
            return nil
        }
        return buffer.removeFirst()
    }
}
