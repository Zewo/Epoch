public final class EventEmitter<T> {
    fileprivate var listeners: [EventListener<T>] = []

    public init() {}

    public func addListener(_ times: Int = -1, listen: @escaping EventListener<T>.Listen) -> EventListener<T> {
        let listener = EventListener<T>(calls: times, listen: listen)
        listeners.append(listener)
        return listener
    }

    public func emit(_ event: T) throws {
        listeners = listeners.filter({ $0.active })

        for listener in listeners {
            let _ = try listener.call(event)
        }
    }
}
