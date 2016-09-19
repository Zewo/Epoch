public struct ReqlChangesOpts : ReqlOpts {
    public let squash: Bool?
    public let includeStates: Bool?
    public let includeInitial: Bool?

    public init(squash: Bool? = nil,
                includeStates: Bool? = nil,
                includeInitial: Bool? = nil) {
        self.squash = squash
        self.includeStates = includeStates
        self.includeInitial = includeInitial
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let squash = self.squash {
            opts["squash"] = squash
        }
        if let includeStates = self.includeStates {
            opts["include_states"] = includeStates
        }
        if let includeInitial = self.includeInitial {
            opts["include_initial"] = includeInitial
        }
        return opts
    }
}
