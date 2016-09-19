public struct ReqlTableOpts : ReqlOpts {
    public let readMode: ReqlReadMode?
    public let identifierFormat: ReqlIdentifierFormat?

    public init(readMode: ReqlReadMode? = nil,
                identifierFormat: ReqlIdentifierFormat? = nil) {
        self.readMode = readMode
        self.identifierFormat = identifierFormat
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let readMode = self.readMode {
            opts["read_mode"] = readMode.rawValue
        }
        if let identifierFormat = self.identifierFormat {
            opts["identifier_format"] = identifierFormat.rawValue
        }
        return opts
    }
}
