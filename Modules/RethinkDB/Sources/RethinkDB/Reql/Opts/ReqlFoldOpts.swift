public struct ReqlFoldOpts : ReqlOpts {
    public let emit: ReqlFunction3?
    public let finalEmit: ReqlFunction1?

    public init(emit: ReqlFunction3? = nil,
                finalEmit: ReqlFunction1? = nil) {
        self.emit = emit
        self.finalEmit = finalEmit
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let emit = self.emit {
            opts["emit"] = emit
        }
        if let finalEmit = self.finalEmit {
            opts["final_emit"] = finalEmit
        }
        return opts
    }
}
