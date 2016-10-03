import Axis

public enum HTTPError {}

public enum ClientError : Error {
    case badRequest(headers: Headers, body: Body)
    case unauthorized(headers: Headers, body: Body)
    case paymentRequired(headers: Headers, body: Body)
    case forbidden(headers: Headers, body: Body)
    case notFound(headers: Headers, body: Body)
    case methodNotAllowed(headers: Headers, body: Body)
    case notAcceptable(headers: Headers, body: Body)
    case proxyAuthenticationRequired(headers: Headers, body: Body)
    case requestTimeout(headers: Headers, body: Body)
    case conflict(headers: Headers, body: Body)
    case gone(headers: Headers, body: Body)
    case lengthRequired(headers: Headers, body: Body)
    case preconditionFailed(headers: Headers, body: Body)
    case requestEntityTooLarge(headers: Headers, body: Body)
    case requestURITooLong(headers: Headers, body: Body)
    case unsupportedMediaType(headers: Headers, body: Body)
    case requestedRangeNotSatisfiable(headers: Headers, body: Body)
    case expectationFailed(headers: Headers, body: Body)
    case imATeapot(headers: Headers, body: Body)
    case authenticationTimeout(headers: Headers, body: Body)
    case enhanceYourCalm(headers: Headers, body: Body)
    case unprocessableEntity(headers: Headers, body: Body)
    case locked(headers: Headers, body: Body)
    case failedDependency(headers: Headers, body: Body)
    case preconditionRequired(headers: Headers, body: Body)
    case tooManyRequests(headers: Headers, body: Body)
    case requestHeaderFieldsTooLarge(headers: Headers, body: Body)
}

extension ClientError {
    public var status: Response.Status {
        switch self {
        case .badRequest: return .badRequest
        case .unauthorized: return .unauthorized
        case .paymentRequired: return .paymentRequired
        case .forbidden: return .forbidden
        case .notFound: return .notFound
        case .methodNotAllowed: return .methodNotAllowed
        case .notAcceptable: return .notAcceptable
        case .proxyAuthenticationRequired: return .proxyAuthenticationRequired
        case .requestTimeout: return .requestTimeout
        case .conflict: return .conflict
        case .gone: return .gone
        case .lengthRequired: return .lengthRequired
        case .preconditionFailed: return .preconditionFailed
        case .requestEntityTooLarge: return .requestEntityTooLarge
        case .requestURITooLong: return .requestURITooLong
        case .unsupportedMediaType: return .unsupportedMediaType
        case .requestedRangeNotSatisfiable: return .requestedRangeNotSatisfiable
        case .expectationFailed: return .expectationFailed
        case .imATeapot: return .imATeapot
        case .authenticationTimeout: return .authenticationTimeout
        case .enhanceYourCalm: return .enhanceYourCalm
        case .unprocessableEntity: return .unprocessableEntity
        case .locked: return .locked
        case .failedDependency: return .failedDependency
        case .preconditionRequired: return .preconditionRequired
        case .tooManyRequests: return .tooManyRequests
        case .requestHeaderFieldsTooLarge: return .requestHeaderFieldsTooLarge
        }
    }
}

extension ClientError : Hashable {
    public var hashValue: Int {
        return status.hashValue
    }
}

extension ClientError : Equatable {}

public func == (lhs: ClientError, rhs: ClientError) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension ClientError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case let .badRequest(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .unauthorized(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .paymentRequired(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .forbidden(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .notFound(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .methodNotAllowed(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .notAcceptable(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .proxyAuthenticationRequired(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .requestTimeout(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .conflict(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .gone(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .lengthRequired(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .preconditionFailed(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .requestEntityTooLarge(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .requestURITooLong(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .unsupportedMediaType(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .requestedRangeNotSatisfiable(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .expectationFailed(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .imATeapot(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .authenticationTimeout(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .enhanceYourCalm(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .unprocessableEntity(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .locked(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .failedDependency(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .preconditionRequired(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .tooManyRequests(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .requestHeaderFieldsTooLarge(headers, body):
            return Response(status: status, headers: headers, body: body)
        }
    }
}

extension HTTPError {
    public static var badRequest: ClientError {
        return ClientError.badRequest(headers: .empty, body: .empty)
    }

    public static var unauthorized: ClientError {
        return ClientError.unauthorized(headers: .empty, body: .empty)
    }

    public static var paymentRequired: ClientError {
        return ClientError.paymentRequired(headers: .empty, body: .empty)
    }

    public static var forbidden: ClientError {
        return ClientError.forbidden(headers: .empty, body: .empty)
    }

    public static var notFound: ClientError {
        return ClientError.notFound(headers: .empty, body: .empty)
    }

    public static var methodNotAllowed: ClientError {
        return ClientError.methodNotAllowed(headers: .empty, body: .empty)
    }

    public static var notAcceptable: ClientError {
        return ClientError.notAcceptable(headers: .empty, body: .empty)
    }

    public static var proxyAuthenticationRequired: ClientError {
        return ClientError.proxyAuthenticationRequired(headers: .empty, body: .empty)
    }

    public static var requestTimeout: ClientError {
        return ClientError.requestTimeout(headers: .empty, body: .empty)
    }

    public static var conflict: ClientError {
        return ClientError.conflict(headers: .empty, body: .empty)
    }

    public static var gone: ClientError {
        return ClientError.gone(headers: .empty, body: .empty)
    }

    public static var lengthRequired: ClientError {
        return ClientError.lengthRequired(headers: .empty, body: .empty)
    }

    public static var preconditionFailed: ClientError {
        return ClientError.preconditionFailed(headers: .empty, body: .empty)
    }

    public static var requestEntityTooLarge: ClientError {
        return ClientError.requestEntityTooLarge(headers: .empty, body: .empty)
    }

    public static var requestURITooLong: ClientError {
        return ClientError.requestURITooLong(headers: .empty, body: .empty)
    }

    public static var unsupportedMediaType: ClientError {
        return ClientError.unsupportedMediaType(headers: .empty, body: .empty)
    }

    public static var requestedRangeNotSatisfiable: ClientError {
        return ClientError.requestedRangeNotSatisfiable(headers: .empty, body: .empty)
    }

    public static var expectationFailed: ClientError {
        return ClientError.expectationFailed(headers: .empty, body: .empty)
    }

    public static var imATeapot: ClientError {
        return ClientError.imATeapot(headers: .empty, body: .empty)
    }

    public static var authenticationTimeout: ClientError {
        return ClientError.authenticationTimeout(headers: .empty, body: .empty)
    }

    public static var enhanceYourCalm: ClientError {
        return ClientError.enhanceYourCalm(headers: .empty, body: .empty)
    }

    public static var unprocessableEntity: ClientError {
        return ClientError.unprocessableEntity(headers: .empty, body: .empty)
    }

    public static var locked: ClientError {
        return ClientError.locked(headers: .empty, body: .empty)
    }

    public static var failedDependency: ClientError {
        return ClientError.failedDependency(headers: .empty, body: .empty)
    }

    public static var preconditionRequired: ClientError {
        return ClientError.preconditionRequired(headers: .empty, body: .empty)
    }

    public static var tooManyRequests: ClientError {
        return ClientError.tooManyRequests(headers: .empty, body: .empty)
    }

    public static var requestHeaderFieldsTooLarge: ClientError {
        return ClientError.requestHeaderFieldsTooLarge(headers: .empty, body: .empty)
    }
}

extension HTTPError {
    public static func badRequest(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.badRequest(headers: headers, body: .buffer(body.buffer))
    }

    public static func unauthorized(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.unauthorized(headers: headers, body: .buffer(body.buffer))
    }

    public static func paymentRequired(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.paymentRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func forbidden(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.forbidden(headers: headers, body: .buffer(body.buffer))
    }

    public static func notFound(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.notFound(headers: headers, body: .buffer(body.buffer))
    }

    public static func methodNotAllowed(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.methodNotAllowed(headers: headers, body: .buffer(body.buffer))
    }

    public static func notAcceptable(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.notAcceptable(headers: headers, body: .buffer(body.buffer))
    }

    public static func proxyAuthenticationRequired(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.proxyAuthenticationRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestTimeout(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.requestTimeout(headers: headers, body: .buffer(body.buffer))
    }

    public static func conflict(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.conflict(headers: headers, body: .buffer(body.buffer))
    }

    public static func gone(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.gone(headers: headers, body: .buffer(body.buffer))
    }

    public static func lengthRequired(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.lengthRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func preconditionFailed(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.preconditionFailed(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestEntityTooLarge(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.requestEntityTooLarge(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestURITooLong(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.requestURITooLong(headers: headers, body: .buffer(body.buffer))
    }

    public static func unsupportedMediaType(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.unsupportedMediaType(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestedRangeNotSatisfiable(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.requestedRangeNotSatisfiable(headers: headers, body: .buffer(body.buffer))
    }

    public static func expectationFailed(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.expectationFailed(headers: headers, body: .buffer(body.buffer))
    }

    public static func imATeapot(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.imATeapot(headers: headers, body: .buffer(body.buffer))
    }

    public static func authenticationTimeout(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.authenticationTimeout(headers: headers, body: .buffer(body.buffer))
    }

    public static func enhanceYourCalm(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.enhanceYourCalm(headers: headers, body: .buffer(body.buffer))
    }

    public static func unprocessableEntity(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.unprocessableEntity(headers: headers, body: .buffer(body.buffer))
    }

    public static func locked(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.locked(headers: headers, body: .buffer(body.buffer))
    }

    public static func failedDependency(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.failedDependency(headers: headers, body: .buffer(body.buffer))
    }

    public static func preconditionRequired(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.preconditionRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func tooManyRequests(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.tooManyRequests(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestHeaderFieldsTooLarge(headers: Headers = .empty, body: BufferRepresentable) -> ClientError {
        return ClientError.requestHeaderFieldsTooLarge(headers: headers, body: .buffer(body.buffer))
    }
}

public enum ServerError : Error {
    case internalServerError(headers: Headers, body: Body)
    case notImplemented(headers: Headers, body: Body)
    case badGateway(headers: Headers, body: Body)
    case serviceUnavailable(headers: Headers, body: Body)
    case gatewayTimeout(headers: Headers, body: Body)
    case httpVersionNotSupported(headers: Headers, body: Body)
    case variantAlsoNegotiates(headers: Headers, body: Body)
    case insufficientStorage(headers: Headers, body: Body)
    case loopDetected(headers: Headers, body: Body)
    case notExtended(headers: Headers, body: Body)
    case networkAuthenticationRequired(headers: Headers, body: Body)
}

extension ServerError {
    public var status: Response.Status {
        switch self {
        case .internalServerError: return .internalServerError
        case .notImplemented: return .notImplemented
        case .badGateway: return .badGateway
        case .serviceUnavailable: return .serviceUnavailable
        case .gatewayTimeout: return .gatewayTimeout
        case .httpVersionNotSupported: return .httpVersionNotSupported
        case .variantAlsoNegotiates: return .variantAlsoNegotiates
        case .insufficientStorage: return .insufficientStorage
        case .loopDetected: return .loopDetected
        case .notExtended: return .notExtended
        case .networkAuthenticationRequired: return .networkAuthenticationRequired
        }
    }
}

extension ServerError : Hashable {
    public var hashValue: Int {
        return status.hashValue
    }
}

extension ServerError : Equatable {}

public func == (lhs: ServerError, rhs: ServerError) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

extension ServerError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case let .internalServerError(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .notImplemented(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .badGateway(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .serviceUnavailable(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .gatewayTimeout(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .httpVersionNotSupported(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .variantAlsoNegotiates(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .insufficientStorage(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .loopDetected(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .notExtended(headers, body):
            return Response(status: status, headers: headers, body: body)
        case let .networkAuthenticationRequired(headers, body):
            return Response(status: status, headers: headers, body: body)
        }
    }
}

extension HTTPError {
    public static var internalServerError: ServerError {
        return ServerError.internalServerError(headers: .empty, body: .empty)
    }

    public static var notImplemented: ServerError {
        return ServerError.notImplemented(headers: .empty, body: .empty)
    }

    public static var badGateway: ServerError {
        return ServerError.badGateway(headers: .empty, body: .empty)
    }

    public static var serviceUnavailable: ServerError {
        return ServerError.serviceUnavailable(headers: .empty, body: .empty)
    }

    public static var gatewayTimeout: ServerError {
        return ServerError.gatewayTimeout(headers: .empty, body: .empty)
    }

    public static var httpVersionNotSupported: ServerError {
        return ServerError.httpVersionNotSupported(headers: .empty, body: .empty)
    }

    public static var variantAlsoNegotiates: ServerError {
        return ServerError.variantAlsoNegotiates(headers: .empty, body: .empty)
    }

    public static var insufficientStorage: ServerError {
        return ServerError.insufficientStorage(headers: .empty, body: .empty)
    }

    public static var loopDetected: ServerError {
        return ServerError.loopDetected(headers: .empty, body: .empty)
    }

    public static var notExtended: ServerError {
        return ServerError.notExtended(headers: .empty, body: .empty)
    }

    public static var networkAuthenticationRequired: ServerError {
        return ServerError.networkAuthenticationRequired(headers: .empty, body: .empty)
    }
}

extension HTTPError {
    public static func internalServerError(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.internalServerError(headers: headers, body: .buffer(body.buffer))
    }

    public static func notImplemented(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.notImplemented(headers: headers, body: .buffer(body.buffer))
    }

    public static func badGateway(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.badGateway(headers: headers, body: .buffer(body.buffer))
    }

    public static func serviceUnavailable(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.serviceUnavailable(headers: headers, body: .buffer(body.buffer))
    }

    public static func gatewayTimeout(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.gatewayTimeout(headers: headers, body: .buffer(body.buffer))
    }

    public static func httpVersionNotSupported(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.httpVersionNotSupported(headers: headers, body: .buffer(body.buffer))
    }

    public static func variantAlsoNegotiates(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.variantAlsoNegotiates(headers: headers, body: .buffer(body.buffer))
    }

    public static func insufficientStorage(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.insufficientStorage(headers: headers, body: .buffer(body.buffer))
    }

    public static func loopDetected(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.loopDetected(headers: headers, body: .buffer(body.buffer))
    }

    public static func notExtended(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.notExtended(headers: headers, body: .buffer(body.buffer))
    }

    public static func networkAuthenticationRequired(headers: Headers = .empty, body: BufferRepresentable) -> ServerError {
        return ServerError.networkAuthenticationRequired(headers: headers, body: .buffer(body.buffer))
    }
}
