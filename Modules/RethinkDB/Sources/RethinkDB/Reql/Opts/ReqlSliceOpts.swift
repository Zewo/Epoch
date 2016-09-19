public struct ReqlSliceOpts : ReqlOpts {
    public let leftBound: ReqlBound?
    public let rightBound: ReqlBound?

    public init(leftBound: ReqlBound? = nil,
                rightBound: ReqlBound? = nil) {
        self.leftBound = leftBound
        self.rightBound = rightBound
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let leftBound = self.leftBound {
            opts["left_bound"] = leftBound.rawValue
        }
        if let rightBound = self.rightBound {
            opts["right_bound"] = rightBound.rawValue
        }
        return opts
    }
}
