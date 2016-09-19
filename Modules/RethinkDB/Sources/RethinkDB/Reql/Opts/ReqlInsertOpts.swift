public struct ReqlInsertOpts : ReqlOpts {
    public let durability: ReqlDurability?
    public let returnChanges: Any?
    public let conflict: ReqlConflict?

    public init(durability: ReqlDurability? = nil,
                returnChanges: Any? = nil,
                conflict: ReqlConflict? = nil) {
        self.durability = durability
        self.returnChanges = returnChanges
        self.conflict = conflict
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let durability = self.durability {
            opts["durability"] = durability.rawValue
        }
        if let returnChanges = self.returnChanges {
            opts["return_changes"] = returnChanges
        }
        if let conflict = self.conflict {
            opts["conflict"] = conflict.rawValue
        }
        return opts
    }
}
