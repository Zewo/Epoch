extension MapInitializable {
    public static var contentMapperKey: String {
        return String(reflecting: type(of: self))
    }
}

public struct ContentMapperMiddleware : Middleware {
    let type: MapInitializable.Type
    public let mode: Mode

    public enum Mode {
        case server
        case client
    }

    public init(mappingTo type: MapInitializable.Type, mode: Mode = .server) {
        self.type = type
        self.mode = mode
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        switch mode {
        case .server:
            return try serverRespond(to: request, chainingTo: next)
        case .client:
            return try clientRespond(to: request, chainingTo: next)
        }
    }

    public func serverRespond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard let content = request.content else {
            return try next.respond(to: request)
        }

        var request = request

        do {
            let target = try type.init(map: content)
            request.storage[type.contentMapperKey] = target
        } catch MapError.incompatibleType {
            // TODO: Use custom error but make it ResponseConvertible
            throw HTTPError.badRequest
        }

        return try next.respond(to: request)
    }

    public func clientRespond(to request: Request, chainingTo next: Responder) throws -> Response {
        var response = try next.respond(to: request)

        guard let content = response.content else {
            return response
        }

        do {
            let target = try type.init(map: content)
            response.storage[type.contentMapperKey] = target
        } catch MapError.incompatibleType {
            // TODO: Use custom error but make it ResponseConvertible
            throw HTTPError.badRequest
        }

        return response
    }
}
