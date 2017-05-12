public final class Session {
    public let token: String
    public var storage: Map = [:]

    init(token: String) {
        self.token = token
    }
}
