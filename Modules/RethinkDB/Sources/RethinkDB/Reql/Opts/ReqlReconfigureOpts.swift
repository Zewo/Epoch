public struct ReqlReconfigureOpts : ReqlOpts {
    public let shards: Int?
    public let replicas: Any?
    public let primaryReplicaTag: String?
    public let dryRun: Bool?
    public let nonVotingReplicaTags: Any?
    public let emergencyRepair: ReqlEmergencyRepair?

    public init(shards: Int? = nil,
                replicas: Any? = nil,
                primaryReplicaTag: String? = nil,
                dryRun: Bool? = nil,
                nonVotingReplicaTags: Any? = nil,
                emergencyRepair: ReqlEmergencyRepair? = nil) {
        self.shards = shards
        self.replicas = replicas
        self.primaryReplicaTag = primaryReplicaTag
        self.dryRun = dryRun
        self.nonVotingReplicaTags = nonVotingReplicaTags
        self.emergencyRepair = emergencyRepair
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let shards = self.shards {
            opts["shards"] = shards
        }
        if let replicas = self.replicas {
            opts["replicas"] = replicas
        }
        if let primaryReplicaTag = self.primaryReplicaTag {
            opts["primary_replica_tag"] = primaryReplicaTag
        }
        if let dryRun = self.dryRun {
            opts["dry_run"] = dryRun
        }
        if let nonVotingReplicaTags = self.nonVotingReplicaTags {
            opts["nonVoting_replicaTags"] = nonVotingReplicaTags
        }
        if let emergencyRepair = self.emergencyRepair {
            opts["emergency_repair"] = emergencyRepair.rawValue
        }
        return opts
    }
}
