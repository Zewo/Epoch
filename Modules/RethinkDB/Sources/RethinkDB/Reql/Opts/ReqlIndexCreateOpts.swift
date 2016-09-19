public struct ReqlIndexCreateOpts : ReqlOpts {
    public let multi: Bool?
    public let geo: Bool?

    public init(multi: Bool? = nil,
                geo: Bool? = nil) {
        self.multi = multi
        self.geo = geo
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let multi = self.multi {
            opts["multi"] = multi
        }
        if let geo = self.geo {
            opts["geo"] = geo
        }
        return opts
    }
}
