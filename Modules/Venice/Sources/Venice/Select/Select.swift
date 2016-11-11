import CLibvenice

protocol SelectCase {
    func register(_ clause: UnsafeMutableRawPointer, index: Int)
    func execute()
}

final class ChannelReceiveCase<T> : SelectCase {
    let channel: Channel<T>
    let closure: (T) -> Void

    init(channel: Channel<T>, closure: @escaping (T) -> Void) {
        self.channel = channel
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.registerReceive(clause, index: index)
    }

    func execute() {
        if let value = channel.getValueFromBuffer() {
            closure(value)
        }
    }
}

final class ReceivingChannelReceiveCase<T> : SelectCase {
    let channel: ReceivingChannel<T>
    let closure: (T) -> Void

    init(channel: ReceivingChannel<T>, closure: @escaping (T) -> Void) {
        self.channel = channel
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.registerReceive(clause, index: index)
    }

    func execute() {
        if let value = channel.getValueFromBuffer() {
            closure(value)
        }
    }
}

final class FallibleChannelReceiveCase<T> : SelectCase {
    let channel: FallibleChannel<T>
    var closure: (ChannelResult<T>) -> Void

    init(channel: FallibleChannel<T>, closure: @escaping (ChannelResult<T>) -> Void) {
        self.channel = channel
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.registerReceive(clause, index: index)
    }

    func execute() {
        if let result = channel.getResultFromBuffer() {
            closure(result)
        }
    }
}

final class FallibleReceivingChannelReceiveCase<T> : SelectCase {
    let channel: FallibleReceivingChannel<T>
    var closure: (ChannelResult<T>) -> Void

    init(channel: FallibleReceivingChannel<T>, closure: @escaping (ChannelResult<T>) -> Void) {
        self.channel = channel
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.registerReceive(clause, index: index)
    }

    func execute() {
        if let result = channel.getResultFromBuffer() {
            closure(result)
        }
    }
}

final class ChannelSendCase<T> : SelectCase {
    let channel: Channel<T>
    var value: T
    let closure: (Void) -> Void

    init(channel: Channel<T>, value: T, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.value = value
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.send(value, clause: clause, index: index)
    }

    func execute() {
        closure()
    }
}

final class SendingChannelSendCase<T> : SelectCase {
    let channel: SendingChannel<T>
    var value: T
    let closure: (Void) -> Void

    init(channel: SendingChannel<T>, value: T, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.value = value
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.send(value, clause: clause, index: index)
    }

    func execute() {
        closure()
    }
}

final class FallibleChannelSendCase<T> : SelectCase {
    let channel: FallibleChannel<T>
    let value: T
    let closure: (Void) -> Void

    init(channel: FallibleChannel<T>, value: T, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.value = value
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.send(value, clause: clause, index: index)
    }

    func execute() {
        closure()
    }
}

final class FallibleSendingChannelSendCase<T> : SelectCase {
    let channel: FallibleSendingChannel<T>
    let value: T
    let closure: (Void) -> Void

    init(channel: FallibleSendingChannel<T>, value: T, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.value = value
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.send(value, clause: clause, index: index)
    }

    func execute() {
        closure()
    }
}

final class FallibleChannelSendErrorCase<T> : SelectCase {
    let channel: FallibleChannel<T>
    let error: Error
    let closure: (Void) -> Void

    init(channel: FallibleChannel<T>, error: Error, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.error = error
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.send(error, clause: clause, index: index)
    }

    func execute() {
        closure()
    }
}

final class FallibleSendingChannelSendErrorCase<T> : SelectCase {
    let channel: FallibleSendingChannel<T>
    let error: Error
    let closure: (Void) -> Void

    init(channel: FallibleSendingChannel<T>, error: Error, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.error = error
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.send(error, clause: clause, index: index)
    }

    func execute() {
        closure()
    }
}

final class TimeoutCase<T> : SelectCase {
    let channel: Channel<T>
    let closure: (Void) -> Void

    init(channel: Channel<T>, closure: @escaping (Void) -> Void) {
        self.channel = channel
        self.closure = closure
    }

    func register(_ clause: UnsafeMutableRawPointer, index: Int) {
        channel.registerReceive(clause, index: index)
    }

    func execute() {
        closure()
    }
}

public class SelectCaseBuilder {
    var cases: [SelectCase] = []
    var otherwise: ((Void) -> Void)?

    public func receive<T>(from channel: Channel<T>?, closure: @escaping (T) -> Void) {
        if let channel = channel {
            let selectCase = ChannelReceiveCase(channel: channel, closure: closure)
            cases.append(selectCase)
        }
    }

    public func receive<T>(from channel: ReceivingChannel<T>?, closure: @escaping (T) -> Void) {
        if let channel = channel {
            let selectCase = ReceivingChannelReceiveCase(channel: channel, closure: closure)
            cases.append(selectCase)
        }
    }

    public func receive<T>(from channel: FallibleChannel<T>?, closure: @escaping (ChannelResult<T>) -> Void) {
        if let channel = channel {
            let selectCase = FallibleChannelReceiveCase(channel: channel, closure: closure)
            cases.append(selectCase)
        }
    }

    public func receive<T>(from channel: FallibleReceivingChannel<T>?, closure: @escaping (ChannelResult<T>) -> Void) {
        if let channel = channel {
            let selectCase = FallibleReceivingChannelReceiveCase(channel: channel, closure: closure)
            cases.append(selectCase)
        }
    }

    public func send<T>(_ value: T, to channel: Channel<T>?, closure: @escaping (Void) -> Void) {
        if let channel = channel, !channel.closed {
            let selectCase = ChannelSendCase(channel: channel, value: value, closure: closure)
            cases.append(selectCase)
        }
    }

    public func send<T>(_ value: T, to channel: SendingChannel<T>?, closure: @escaping (Void) -> Void) {
        if let channel = channel, !channel.closed {
            let selectCase = SendingChannelSendCase(channel: channel, value: value, closure: closure)
            cases.append(selectCase)
        }
    }

    public func send<T>(_ value: T, to channel: FallibleChannel<T>?, closure: @escaping (Void) -> Void) {
        if let channel = channel, !channel.closed {
            let selectCase = FallibleChannelSendCase(channel: channel, value: value, closure: closure)
            cases.append(selectCase)
        }
    }

    public func send<T>(_ value: T, to channel: FallibleSendingChannel<T>?, closure: @escaping (Void) -> Void) {
        if let channel = channel, !channel.closed {
            let selectCase = FallibleSendingChannelSendCase(channel: channel, value: value, closure: closure)
            cases.append(selectCase)
        }
    }

    public func send<T>(_ error: Error, to channel: FallibleChannel<T>?, closure: @escaping (Void) -> Void) {
        if let channel = channel, !channel.closed {
            let selectCase = FallibleChannelSendErrorCase(channel: channel, error: error, closure: closure)
            cases.append(selectCase)
        }
    }

    public func send<T>(_ error: Error, to channel: FallibleSendingChannel<T>?, closure: @escaping (Void) -> Void) {
        if let channel = channel, !channel.closed {
            let selectCase = FallibleSendingChannelSendErrorCase(channel: channel, error: error, closure: closure)
            cases.append(selectCase)
        }
    }

    public func timeout(_ deadline: Double, closure: @escaping (Void) -> Void) {
        let done = Channel<Bool>()
        co {
            wake(at: deadline)
            done.send(true)
        }
        let selectCase = TimeoutCase<Bool>(channel: done, closure: closure)
        cases.append(selectCase)
    }

    public func otherwise(_ closure: @escaping (Void) -> Void) {
        self.otherwise = closure
    }
}

private func select(_ builder: SelectCaseBuilder) {
    mill_choose_init_("select")

    var clauses: [UnsafeMutableRawPointer] = []

    for (index, selectCase) in builder.cases.enumerated() {
        let clause = malloc(mill_clauselen())!
        clauses.append(clause)
        selectCase.register(clause, index: index)
    }

    if builder.otherwise != nil {
        mill_choose_otherwise_()
    }

    let index = mill_choose_wait_()

    if index == -1 {
        builder.otherwise?()
    } else {
        builder.cases[Int(index)].execute()
    }

    clauses.forEach(free)
}

public func select(_ build: (_ when: SelectCaseBuilder) -> Void) {
    let builder = SelectCaseBuilder()
    build(builder)
    select(builder)
}

public func sel(_ build: (_ when: SelectCaseBuilder) -> Void) {
    select(build)
}

public func forSelect(_ build: (_ when: SelectCaseBuilder, _ done: @escaping (Void) -> Void) -> Void) {
    let builder = SelectCaseBuilder()
    var keepRunning = true
    func done() {
        keepRunning = false
    }
    while keepRunning {
        let builder = SelectCaseBuilder()
        build(builder, done)
        select(builder)
    }
}

public func forSel(build: (_ when: SelectCaseBuilder, _ done: @escaping (Void) -> Void) -> Void) {
    forSelect(build)
}
