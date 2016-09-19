public struct ReqlReplaceOpts : ReqlOpts {
    public let durability: ReqlDurability?
    public let returnChanges: Any?
    public let nonAtomic: Bool?

    public init(durability: ReqlDurability? = nil,
                returnChanges: Any? = nil,
                nonAtomic: Bool? = nil) {
        self.durability = durability
        self.returnChanges = returnChanges
        self.nonAtomic = nonAtomic
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let durability = self.durability {
            opts["durability"] = durability.rawValue
        }
        if let returnChanges = self.returnChanges {
            opts["return_changes"] = returnChanges
        }
        if let nonAtomic = self.nonAtomic {
            opts["non_atomic"] = nonAtomic
        }
        return opts
    }
}
