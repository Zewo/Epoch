public struct ReqlTableCreateOpts : ReqlOpts {
    public let primaryKey: String?
    public let durability: ReqlDurability?
    public let shards: Int?
    public let replicas: Any?
    public let primaryReplicaTag: String?

    public init(primaryKey: String? = nil,
                durability: ReqlDurability? = nil,
                shards: Int? = nil,
                replicas: Any? = nil,
                primaryReplicaTag: String? = nil) {
        self.primaryKey = primaryKey
        self.durability = durability
        self.shards = shards
        self.replicas = replicas
        self.primaryReplicaTag = primaryReplicaTag
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let primaryKey = self.primaryKey {
            opts["primary_key"] = primaryKey
        }
        if let durability = self.durability {
            opts["durability"] = durability.rawValue
        }
        if let shards = self.shards {
            opts["shards"] = shards
        }
        if let replicas = self.replicas {
            opts["replicas"] = replicas
        }
        if let primaryReplicaTag = self.primaryReplicaTag {
            opts["primary_replica_tag"] = primaryReplicaTag
        }
        return opts
    }
}
