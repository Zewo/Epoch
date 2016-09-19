public struct ReqlIndexRenameOpts : ReqlOpts {
    public let overwrite: Bool?

    public init(overwrite: Bool? = nil) {
        self.overwrite = overwrite
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let overwrite = self.overwrite {
            opts["overwrite"] = overwrite
        }
        return opts
    }
}
