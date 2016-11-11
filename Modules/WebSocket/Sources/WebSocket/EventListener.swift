public final class EventListener<T> {
    public typealias Listen = (T) throws -> Void

    fileprivate let listen: Listen
    fileprivate var calls: Int
    var active = true

    init(calls: Int, listen: @escaping Listen) {
        self.calls = calls
        self.listen = listen
    }

    func call(_ event: T) throws -> Bool {
        calls -= 1

        if calls == 0 {
            active = false
        }

        try listen(event)
        return active
    }

    public func stop() {
        active = false
    }
}
