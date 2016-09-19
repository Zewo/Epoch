public struct ReqlUnionOpts : ReqlOpts {
    public let interleave: Any?

    public init(interleave: Any? = nil) {
        self.interleave = interleave
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let interleave = self.interleave {
            opts["interleave"] = interleave
        }
        return opts
    }
}
