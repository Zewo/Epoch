public struct ReqlGetNearest : ReqlOpts {
    public let index: String?
    public let maxResults: Int?
    public let unit: ReqlUnit?
    public let maxDistance: Double?
    public let geoSystem: ReqlGeoSystem?

    public init(index: String? = nil,
                maxResults: Int? = nil,
                unit: ReqlUnit? = nil,
                maxDistance: Double? = nil,
                geoSystem: ReqlGeoSystem? = nil) {
        self.index = index
        self.maxResults = maxResults
        self.unit = unit
        self.maxDistance = maxDistance
        self.geoSystem = geoSystem
    }

    public var rawValue: [String: Any] {
        var opts: [String: Any] = [:]
        if let index = self.index {
            opts["index"] = index
        }
        if let maxResults = self.maxResults {
            opts["max_results"] = maxResults
        }
        if let unit = self.unit {
            opts["unit"] = unit.rawValue
        }
        if let maxDistance = self.maxDistance {
            opts["max_distance"] = maxDistance
        }
        if let geoSystem = self.geoSystem {
            opts["geo_system"] = geoSystem
        }
        return opts
    }
}
