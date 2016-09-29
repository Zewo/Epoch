public final class Ticker {
    private let internalChannel = Channel<Double>()
    private var stopped: Bool = false

    public var channel: ReceivingChannel<Double> {
        return internalChannel.receivingChannel
    }

    public init(period: Double) {
        co {
            while true {
                nap(for: period)
                if self.stopped { break }
                self.internalChannel.send(now())
            }
        }
    }

    public func stop() {
        self.stopped = true
    }
}
