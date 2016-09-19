public struct ReqlFilterOpts : ReqlOpts {
    public let `default`: Any?

    public init(default: Any? = nil) {
        self.`default` = `default`
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let `default` = self.`default` {
            opts["default"] = `default`
        }
        return opts
    }
}
