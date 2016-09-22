public struct RedirectMiddleware : Middleware {
    let location: String
    let shouldRedirect: (Request) -> Bool

    public init(redirectTo location: String, if shouldRedirect: @escaping (Request) -> Bool) {
        self.location = location
        self.shouldRedirect = shouldRedirect
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        if shouldRedirect(request) {
            return Response(redirectTo: location)
        }

        return try chain.respond(to: request)
    }
}

extension Response {
    public init(redirectTo location: String, headers: Headers = [:]) {
        var headers = headers
        headers["location"] = location
        self.init(status: .found, headers: headers)
    }
}
