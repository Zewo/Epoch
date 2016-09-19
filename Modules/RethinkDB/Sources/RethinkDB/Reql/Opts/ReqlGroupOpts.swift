public struct ReqlGroupOpts : ReqlOpts {
    public let index: String?
    public let multi: Bool?

    public init(index: String? = nil,
                multi: Bool? = nil) {
        self.index = index
        self.multi = multi
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let index = self.index {
            opts["index"] = index
        }
        if let multi = self.multi {
            opts["multi"] = multi
        }
        return opts
    }
}
