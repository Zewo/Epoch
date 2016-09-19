public struct ReqlISO8601Opts : ReqlOpts {
    public let defaultTimezone: String?

    public init(defaultTimezone: String? = nil) {
        self.defaultTimezone = defaultTimezone
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let defaultTimezone = self.defaultTimezone {
            opts["default_timezone"] = defaultTimezone
        }
        return opts
    }
}
