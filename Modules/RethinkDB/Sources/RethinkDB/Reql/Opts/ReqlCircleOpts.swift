public struct ReqlCircleOpts : ReqlOpts {
    public let numVertices: Any?
    public let geoSystem: ReqlGeoSystem?
    public let unit: ReqlUnit?
    public let fill: Bool?

    public init(numVertices: Any? = nil,
                geoSystem: ReqlGeoSystem? = nil,
                unit: ReqlUnit? = nil,
                fill: Bool? = nil) {
        self.numVertices = numVertices
        self.geoSystem = geoSystem
        self.unit = unit
        self.fill = fill
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let numVertices = self.numVertices {
            opts["num_vertices"] = numVertices
        }
        if let geoSystem = self.geoSystem {
            opts["geo_system"] = geoSystem.rawValue
        }
        if let unit = self.unit {
            opts["unit"] = unit.rawValue
        }
        if let fill = self.fill {
            opts["fill"] = fill
        }
        return opts
    }
}
