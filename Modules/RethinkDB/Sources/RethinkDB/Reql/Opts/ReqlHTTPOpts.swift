public typealias ReqlHTTPAuth = (type: ReqlAuthType, user: String, pass: String)
public struct ReqlHTTPOpts : ReqlOpts {
    public let timeout: Int?
    public let reattempts: Int?
    public let redirects: Int?
    public let verify: Bool?
    public let resultFormat: ReqlResultFormat?
    public let method: ReqlHTTPMethod?
    public let auth: ReqlHTTPAuth?
    public let params: [String: Any]?
    public let headers: Any?
    public let data: Any?

    public init(timeout: Int? = nil,
                reattempts: Int? = nil,
                redirects: Int? = nil,
                verify: Bool? = nil,
                resultFormat: ReqlResultFormat? = nil,
                method: ReqlHTTPMethod? = nil,
                auth: ReqlHTTPAuth? = nil,
                params: [String: Any]? = nil,
                headers: Any? = nil,
                data: Any? = nil) {
        self.timeout = timeout
        self.reattempts = reattempts
        self.redirects = redirects
        self.verify = verify
        self.resultFormat = resultFormat
        self.method = method
        self.auth = auth
        self.params = params
        self.headers = headers
        self.data = data
    }

    public var rawValue: [String : Any] {
        var opts: [String: Any] = [:]
        if let timeout = self.timeout {
            opts["timeout"] = timeout
        }
        if let reattempts = self.reattempts {
            opts["reattempts"] = reattempts
        }
        if let redirects = self.redirects {
            opts["redirects"] = redirects
        }
        if let verify = self.verify {
            opts["verify"] = verify
        }
        if let resultFormat = self.resultFormat {
            opts["result_format"] = resultFormat.rawValue
        }
        if let method = self.method {
            opts["method"] = method.rawValue
        }
        if let auth = self.auth {
            opts["auth"] = ["type": auth.type.rawValue, "user": auth.user, "pass": auth.pass]
        }
        if let params = self.params {
            opts["params"] = params
        }
        if let headers = self.headers {
            opts["headers"] = headers
        }
        if let data = self.data {
            opts["data"] = data
        }
        return opts
    }
}
