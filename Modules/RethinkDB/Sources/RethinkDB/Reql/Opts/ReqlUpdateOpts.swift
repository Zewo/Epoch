public struct ReqlUpdateOpts : ReqlOpts {
    public let durability: ReqlDurability?
    public let returnChanges: Any?

    public init(durability: ReqlDurability? = nil,
                returnChanges: Any? = nil) {
        self.durability = durability
        self.returnChanges = returnChanges
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let durability = self.durability {
            opts["durability"] = durability.rawValue
        }
        if let returnChanges = self.returnChanges {
            opts["return_changes"] = returnChanges
        }
        return opts
    }
}
