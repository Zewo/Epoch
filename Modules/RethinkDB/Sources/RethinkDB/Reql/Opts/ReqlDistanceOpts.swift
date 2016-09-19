public struct ReqlDistanceOpts : ReqlOpts {
    public let geoSystem: ReqlGeoSystem?
    public let unit: ReqlUnit?

    public init(geoSystem: ReqlGeoSystem? = nil,
                unit: ReqlUnit? = nil) {
        self.geoSystem = geoSystem
        self.unit = unit
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let geoSystem = self.geoSystem {
            opts["geo_system"] = geoSystem.rawValue
        }
        if let unit = self.unit {
            opts["unit"] = unit.rawValue
        }
        return opts
    }
}
