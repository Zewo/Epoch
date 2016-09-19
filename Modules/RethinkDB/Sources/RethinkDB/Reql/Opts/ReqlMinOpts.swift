public struct ReqlMinOpts : ReqlOpts {
    public let index: String?

    public init(index: String? = nil) {
        self.index = index
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let index = self.index {
            opts["index"] = index
        }
        return opts
    }
}
