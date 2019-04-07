public struct Version {
    public var major: Int
    public var minor: Int

    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }

    public static let oneDotZero = Version(major: 1, minor: 0)
    public static let oneDotOne = Version(major: 1, minor: 1)
}

extension Version : Hashable {
    /// :nodoc:
    public var hashValue: Int {
        return major ^ minor
    }

    /// :nodoc:
    public static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Version : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        return "HTTP/" + major.stringValue + "." + minor.stringValue
    }
}
