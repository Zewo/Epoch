public enum ReqlStatus : String {
    case readyForOutdatedReads = "ready_for_outdated_reads"
    case readyForReads = "ready_for_reads"
    case readyForWrites = "ready_for_writes"
    case allReplicasReady = "all_replicas_ready"
}
