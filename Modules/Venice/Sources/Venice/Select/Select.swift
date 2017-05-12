import CLibdill

protocol SelectCase {
    var clause: chclause { get }
    func execute(error: Error?) throws
    func free()
}

final class SendCase<T> : SelectCase {
    let clause: chclause
    var result: ChannelResult<T>
    let closure: (ChannelResult<Void>) throws -> Void

    init(handle: HandleDescriptor, result: ChannelResult<T>, closure: @escaping (ChannelResult<Void>) throws -> Void) {
        self.result = result

        clause = withUnsafeMutablePointer(to: &self.result) { value in
            chclause(op: CHSEND, ch: handle, val: value, len: Channel<T>.length)
        }

        self.closure = closure
    }

    func execute(error: Error?) throws {
        if let error = error {
            try closure(.error(error))
        } else {
            try closure(.value())
        }
    }

    func free() {}
}

final class ReceiveCase<T> : SelectCase {
    let clause: chclause
    var value: UnsafeMutablePointer<ChannelResult<T>>
    let closure: (ChannelResult<T>) throws -> Void

    init(handle: HandleDescriptor, closure: @escaping (ChannelResult<T>) throws -> Void) {
        value = UnsafeMutablePointer<ChannelResult<T>>.allocate(capacity: 1)
        clause = chclause(op: CHRECV, ch: handle, val: value, len: Channel<T>.length)
        self.closure = closure
    }

    func execute(error: Error?) throws {
        if let error = error {
            try closure(.error(error))
        } else {
            try closure(value.pointee)
        }
    }

    func free() {
        value.deallocate(capacity: 1)
    }
}

public class SelectCaseBuilder {
    var cases: [SelectCase] = []
    var deadline: Deadline = .never
    var timeout: ((Void) throws -> Void)? = nil

    public func send<T>(_ value: T, to channel: Channel<T>?, closure: @escaping (ChannelResult<Void>) throws -> Void) {
        send(result: ChannelResult<T>.value(value), handle: channel?.handle, closure: closure)
    }

    public func send<T>(_ value: T, to channel: SendingChannel<T>?, closure: @escaping (ChannelResult<Void>) throws -> Void) {
        send(result: ChannelResult<T>.value(value), handle: channel?.handle, closure: closure)
    }

    public func send<T>(_ error: Error, to channel: Channel<T>?, closure: @escaping (ChannelResult<Void>) throws -> Void) {
        send(result: ChannelResult<T>.error(error), handle: channel?.handle, closure: closure)
    }

    public func send<T>(_ error: Error, to channel: SendingChannel<T>?, closure: @escaping (ChannelResult<Void>) throws -> Void) {
        send(result: ChannelResult<T>.error(error), handle: channel?.handle, closure: closure)
    }

    private func send<T>(result: ChannelResult<T>, handle: HandleDescriptor?, closure: @escaping (ChannelResult<Void>) throws -> Void) {
        guard let handle = handle else {
            return
        }

        cases.append(SendCase<T>(handle: handle, result: result, closure: closure))
    }

    public func receive<T>(from channel: Channel<T>?, closure: @escaping (ChannelResult<T>) throws -> Void) {
        receive(handle: channel?.handle, closure: closure)
    }

    public func receive<T>(from channel: ReceivingChannel<T>?, closure: @escaping (ChannelResult<T>) throws -> Void) {
        receive(handle: channel?.handle, closure: closure)
    }

    private func receive<T>(handle: HandleDescriptor?, closure: @escaping (ChannelResult<T>) throws -> Void) {
        guard let handle = handle else {
            return
        }

        cases.append(ReceiveCase<T>(handle: handle, closure: closure))
    }

    public func timeout(deadline: Deadline, _ timeout: @escaping (Void) throws -> Void) {
        self.deadline = deadline
        self.timeout = timeout
    }
}

private func select(builder: SelectCaseBuilder) throws {
    defer {
        builder.cases.forEach({ $0.free() })
    }

    var clauses = builder.cases.map({ $0.clause })
    let result = choose(&clauses, Int32(clauses.count), builder.deadline)

    guard result != -1 else {
        switch errno {
        case ECANCELED:
            throw VeniceError.canceled
        case ETIMEDOUT:
            guard let timeout = builder.timeout else {
                throw VeniceError.timeout
            }

            return try timeout()
        default:
            throw VeniceError.unexpected
        }
    }

    let error: Error?

    switch errno {
    case 0:
        error = nil
    case EBADF:
        error = VeniceError.invalidHandle
    case EINVAL:
        error = VeniceError.invalidParameter
    case ENOTSUP:
        error = VeniceError.operationNotSupported
    case EPIPE:
        error = VeniceError.channelIsDone
    default:
        error = VeniceError.unexpected
    }

    try builder.cases[Int(result)].execute(error: error)
    try Venice.yield()
}

public func select(build: (_ when: SelectCaseBuilder) -> Void) throws {
    let builder = SelectCaseBuilder()
    build(builder)
    try select(builder: builder)
}

public func forSelect(build: (_ when: SelectCaseBuilder, _ done: @escaping (Void) -> Void) -> Void) throws {
    var keepRunning = true

    func done() {
        keepRunning = false
    }

    while keepRunning {
        let builder = SelectCaseBuilder()
        build(builder, done)
        try select(builder: builder)
    }
}
