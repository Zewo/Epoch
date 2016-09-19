public struct ReqlRandomOpts : ReqlOpts {
    public let float: Bool?

    public init(float: Bool? = nil) {
        self.float = float
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let float = self.float {
            opts["float"] = float
        }
        return opts
    }
}
