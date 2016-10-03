public protocol Host {
    func accept(deadline: Double) throws -> Stream
}

extension Host {
    public func accept() throws -> Stream {
        return try accept(deadline: .never)
    }
}
