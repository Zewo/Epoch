private var uuidCount = 0

private func uuid() -> String {
    uuidCount += 1
    return String(uuidCount)
}

public struct SessionMiddleware: Middleware {
    public static let cookieName = "zewo-session"
    public let storage: SessionStorage

    public init(storage: SessionStorage = SessionInMemoryStorage()) {
        self.storage = storage
    }

    public func respond(to request: Request, chainingTo chain: Responder) throws -> Response {
        var request = request
        let (cookie, createdCookie) = getOrCreateCookie(request: request)

        // ensure that we have a session and add it to the request
        let session = getExistingSession(cookie: cookie) ?? createNewSession(cookie: cookie)
        add(session: session, toRequest: &request)

        // at this point, we have a cookie and a session. call the rest of the chain!
        var response = try chain.respond(to: request)

        // if no cookie was originally in the request, we should put it in the response
        if createdCookie {
            let cookie = AttributedCookie(name: cookie.name, value: cookie.value)
            response.cookies.insert(cookie)
        }

        // done! response have the session cookie and request has the session
        return response
    }

    private func getOrCreateCookie(request: Request) -> (Cookie, Bool) {
        // if request contains a session cookie, return that cookie
        if let requestCookie = request.cookies.filter({ $0.name == SessionMiddleware.cookieName }).first {
            return (requestCookie, false)
        }

        // otherwise, create a new cookie
        let cookie = Cookie(name: SessionMiddleware.cookieName, value: uuid())
        return (cookie, true)
    }

    private func getExistingSession(cookie: Cookie) -> Session? {
        return storage.fetchSession(key: cookie.extendedHash)
    }

    private func createNewSession(cookie: Cookie) -> Session {
        // where cookie.value is the cookie uuid
        let session = Session(token: cookie.value)
        storage.save(key: cookie.extendedHash, session: session)
        return session
    }

    private func add(session: Session, toRequest request: inout Request) {
        request.storage[SessionMiddleware.cookieName] = session
    }
}

extension Request {
    // TODO: Add a Quark compiler flag and then make different versions Session/Session?
    public var session: Session {
        guard let session = storage[SessionMiddleware.cookieName] as? Session else {
            fatalError("SessionMiddleware should be applied to the chain. Quark guarantees it, so this error should never happen within Quark.")
        }
        return session
    }
}

extension Cookie {
    public typealias Hash = Int
    public var extendedHash: Hash {
        return "\(name)+\(value)".hashValue
    }
}
