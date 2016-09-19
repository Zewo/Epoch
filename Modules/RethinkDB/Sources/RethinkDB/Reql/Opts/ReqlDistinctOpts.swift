public struct ReqlDistinctOpts : ReqlOpts {
    public let index: Any?

    public init(index: Any? = nil) {
        self.index = index
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let index = self.index {
            opts["index"] = index
        }
        return opts
    }
}
