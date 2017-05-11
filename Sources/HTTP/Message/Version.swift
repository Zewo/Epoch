public struct Version {
    public var major: Int
    public var minor: Int

    public init(major: Int, minor: Int) {
        self.major = major
        self.minor = minor
    }
}

extension Version : Hashable {
    public var hashValue: Int {
        return major ^ minor
    }
}

extension Version : Equatable {}

public func == (lhs: Version, rhs: Version) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension Version {
    public static let oneDotZero = Version(major: 1, minor: 0)
    public static let oneDotOne = Version(major: 1, minor: 1)
}

extension Version : CustomStringConvertible {
    public var description: String {
        return "HTTP/" + major.description + "." + minor.description
    }
}
