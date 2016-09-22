public protocol Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response
}

extension Middleware {
    public func chain(to responder: Responder) -> Responder {
        return BasicResponder { (request: Request) throws -> Response in
            return try self.respond(to: request, chainingTo: responder)
        }
    }
}

extension Collection where Self.Iterator.Element == Middleware {
    public func chain(to responder: Responder) -> Responder {
        var responder = responder

        for middleware in self.reversed() {
            responder = middleware.chain(to: responder)
        }

        return responder
    }
}
