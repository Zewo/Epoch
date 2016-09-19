public struct ReqlJavascriptOpts : ReqlOpts {
    public let timeout: Int?

    public init(timeout: Int? = nil) {
        self.timeout = timeout
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let timeout = self.timeout {
            opts["timeout"] = timeout
        }
        return opts
    }
}
