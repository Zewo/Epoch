import CLibvenice

public struct ChannelGenerator<T> : IteratorProtocol {
    internal let channel: ReceivingChannel<T>

    public mutating func next() -> T? {
        return channel.receive()
    }
}

public final class Channel<T> : Sequence {
    private let channel: chan
    public var closed: Bool = false
    private var buffer: [T] = []
    public let bufferSize: Int
    
    public convenience init() {
        self.init(bufferSize: 0)
    }

    public init(bufferSize: Int) {
        self.bufferSize = bufferSize
        self.channel = mill_chmake_(bufferSize, "Channel init")
    }

    deinit {
        mill_chclose_(channel, "Channel deinit")
    }

    /// Reference that can only send values.
    public lazy var sendingChannel: SendingChannel<T> = SendingChannel(self)

    /// Reference that can only receive values.
    public lazy var receivingChannel: ReceivingChannel<T> = ReceivingChannel(self)

    /// Creates a generator.
    public func makeIterator() -> ChannelGenerator<T> {
        return ChannelGenerator(channel: receivingChannel)
    }

    /// Closes the channel. When a channel is closed it cannot receive values anymore.
    public func close() {
        guard !closed else { return }

        closed = true
        mill_chdone_(channel, "Channel close")
    }

    /// Send a value to the channel.
    public func send(_ value: T) {
        if !closed {
            buffer.append(value)
            mill_chs_(channel, "Channel send")
        }
    }

    internal func send(_ value: T, clause: UnsafeMutableRawPointer, index: Int) {
        if !closed {
            buffer.append(value)
            mill_choose_out_(clause, channel, Int32(index))
        }
    }

    /// Receives a value from the channel.
    @discardableResult
    public func receive() -> T? {
        if closed && buffer.isEmpty {
            return nil
        }
        mill_chr_(channel, "Channel receive")
        return getValueFromBuffer()
    }

    internal func registerReceive(_ clause: UnsafeMutableRawPointer, index: Int) {
        mill_choose_in_(clause, channel, Int32(index))
    }

    internal func getValueFromBuffer() -> T? {
        if closed && buffer.isEmpty {
            return nil
        }
        return buffer.removeFirst()
    }
}
