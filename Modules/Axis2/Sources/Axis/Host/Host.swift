public protocol Host {
    func accept(deadline: Double) throws -> Stream
}
