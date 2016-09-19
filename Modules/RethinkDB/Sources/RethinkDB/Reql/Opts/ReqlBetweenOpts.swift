public struct ReqlBetweenOpts : ReqlOpts {
    public let index: String?
    public let leftBound: ReqlBound?
    public let rightBound: ReqlBound?

    public init(index: String? = nil,
                leftBound: ReqlBound? = nil,
                rightBound: ReqlBound? = nil) {
        self.index = index
        self.leftBound = leftBound
        self.rightBound = rightBound
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let index = self.index {
            opts["index"] = index
        }
        if let leftBound = self.leftBound {
            opts["left_bound"] = leftBound.rawValue
        }
        if let rightBound = self.rightBound {
            opts["right_bound"] = rightBound.rawValue
        }
        return opts
    }
}
