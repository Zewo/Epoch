public protocol Connection : Stream {
    func open(deadline: Double) throws
}

extension Connection {
    public func open() throws {
        return try open(deadline: .never)
    }
}
