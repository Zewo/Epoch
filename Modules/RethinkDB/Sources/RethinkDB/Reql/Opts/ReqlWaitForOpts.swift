public struct ReqlWaitForOpts : ReqlOpts {
    public let waitFor: ReqlStatus?
    public let timeout: Int?

    public init(waitFor: ReqlStatus? = nil,
                timeout: Int? = nil) {
        self.waitFor = waitFor
        self.timeout = timeout
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let waitFor = self.waitFor {
            opts["wait_for"] = waitFor.rawValue
        }
        if let timeout = self.timeout {
            opts["timeout"] = timeout
        }
        return opts
    }
}
