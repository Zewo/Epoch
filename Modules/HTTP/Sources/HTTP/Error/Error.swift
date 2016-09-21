import Core

public struct HTTPError {}

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

extension ClientError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case let .badRequest(headers, body):
            return Response(status: .badRequest, headers: headers, body: body)
        case let .unauthorized(headers, body):
            return Response(status: .unauthorized, headers: headers, body: body)
        case let .paymentRequired(headers, body):
            return Response(status: .paymentRequired, headers: headers, body: body)
        case let .forbidden(headers, body):
            return Response(status: .forbidden, headers: headers, body: body)
        case let .notFound(headers, body):
            return Response(status: .notFound, headers: headers, body: body)
        case let .methodNotAllowed(headers, body):
            return Response(status: .methodNotAllowed, headers: headers, body: body)
        case let .notAcceptable(headers, body):
            return Response(status: .notAcceptable, headers: headers, body: body)
        case let .proxyAuthenticationRequired(headers, body):
            return Response(status: .proxyAuthenticationRequired, headers: headers, body: body)
        case let .requestTimeout(headers, body):
            return Response(status: .requestTimeout, headers: headers, body: body)
        case let .conflict(headers, body):
            return Response(status: .conflict, headers: headers, body: body)
        case let .gone(headers, body):
            return Response(status: .gone, headers: headers, body: body)
        case let .lengthRequired(headers, body):
            return Response(status: .lengthRequired, headers: headers, body: body)
        case let .preconditionFailed(headers, body):
            return Response(status: .preconditionFailed, headers: headers, body: body)
        case let .requestEntityTooLarge(headers, body):
            return Response(status: .requestEntityTooLarge, headers: headers, body: body)
        case let .requestURITooLong(headers, body):
            return Response(status: .requestURITooLong, headers: headers, body: body)
        case let .unsupportedMediaType(headers, body):
            return Response(status: .unsupportedMediaType, headers: headers, body: body)
        case let .requestedRangeNotSatisfiable(headers, body):
            return Response(status: .requestedRangeNotSatisfiable, headers: headers, body: body)
        case let .expectationFailed(headers, body):
            return Response(status: .expectationFailed, headers: headers, body: body)
        case let .imATeapot(headers, body):
            return Response(status: .imATeapot, headers: headers, body: body)
        case let .authenticationTimeout(headers, body):
            return Response(status: .authenticationTimeout, headers: headers, body: body)
        case let .enhanceYourCalm(headers, body):
            return Response(status: .enhanceYourCalm, headers: headers, body: body)
        case let .unprocessableEntity(headers, body):
            return Response(status: .unprocessableEntity, headers: headers, body: body)
        case let .locked(headers, body):
            return Response(status: .locked, headers: headers, body: body)
        case let .failedDependency(headers, body):
            return Response(status: .failedDependency, headers: headers, body: body)
        case let .preconditionRequired(headers, body):
            return Response(status: .preconditionRequired, headers: headers, body: body)
        case let .tooManyRequests(headers, body):
            return Response(status: .tooManyRequests, headers: headers, body: body)
        case let .requestHeaderFieldsTooLarge(headers, body):
            return Response(status: .requestHeaderFieldsTooLarge, headers: headers, body: body)
        }
    }
}

extension HTTPError {
    public static var badRequest: ClientError {
        return ClientError.badRequest(headers: [:], body: .buffer(Buffer()))
    }

    public static var unauthorized: ClientError {
        return ClientError.unauthorized(headers: [:], body: .buffer(Buffer()))
    }

    public static var paymentRequired: ClientError {
        return ClientError.paymentRequired(headers: [:], body: .buffer(Buffer()))
    }

    public static var forbidden: ClientError {
        return ClientError.forbidden(headers: [:], body: .buffer(Buffer()))
    }

    public static var notFound: ClientError {
        return ClientError.notFound(headers: [:], body: .buffer(Buffer()))
    }

    public static var methodNotAllowed: ClientError {
        return ClientError.methodNotAllowed(headers: [:], body: .buffer(Buffer()))
    }

    public static var notAcceptable: ClientError {
        return ClientError.notAcceptable(headers: [:], body: .buffer(Buffer()))
    }

    public static var proxyAuthenticationRequired: ClientError {
        return ClientError.proxyAuthenticationRequired(headers: [:], body: .buffer(Buffer()))
    }

    public static var requestTimeout: ClientError {
        return ClientError.requestTimeout(headers: [:], body: .buffer(Buffer()))
    }

    public static var conflict: ClientError {
        return ClientError.conflict(headers: [:], body: .buffer(Buffer()))
    }

    public static var gone: ClientError {
        return ClientError.gone(headers: [:], body: .buffer(Buffer()))
    }

    public static var lengthRequired: ClientError {
        return ClientError.lengthRequired(headers: [:], body: .buffer(Buffer()))
    }

    public static var preconditionFailed: ClientError {
        return ClientError.preconditionFailed(headers: [:], body: .buffer(Buffer()))
    }

    public static var requestEntityTooLarge: ClientError {
        return ClientError.requestEntityTooLarge(headers: [:], body: .buffer(Buffer()))
    }

    public static var requestURITooLong: ClientError {
        return ClientError.requestURITooLong(headers: [:], body: .buffer(Buffer()))
    }

    public static var unsupportedMediaType: ClientError {
        return ClientError.unsupportedMediaType(headers: [:], body: .buffer(Buffer()))
    }

    public static var requestedRangeNotSatisfiable: ClientError {
        return ClientError.requestedRangeNotSatisfiable(headers: [:], body: .buffer(Buffer()))
    }

    public static var expectationFailed: ClientError {
        return ClientError.expectationFailed(headers: [:], body: .buffer(Buffer()))
    }

    public static var imATeapot: ClientError {
        return ClientError.imATeapot(headers: [:], body: .buffer(Buffer()))
    }

    public static var authenticationTimeout: ClientError {
        return ClientError.authenticationTimeout(headers: [:], body: .buffer(Buffer()))
    }

    public static var enhanceYourCalm: ClientError {
        return ClientError.enhanceYourCalm(headers: [:], body: .buffer(Buffer()))
    }

    public static var unprocessableEntity: ClientError {
        return ClientError.unprocessableEntity(headers: [:], body: .buffer(Buffer()))
    }

    public static var locked: ClientError {
        return ClientError.locked(headers: [:], body: .buffer(Buffer()))
    }

    public static var failedDependency: ClientError {
        return ClientError.failedDependency(headers: [:], body: .buffer(Buffer()))
    }

    public static var preconditionRequired: ClientError {
        return ClientError.preconditionRequired(headers: [:], body: .buffer(Buffer()))
    }

    public static var tooManyRequests: ClientError {
        return ClientError.tooManyRequests(headers: [:], body: .buffer(Buffer()))
    }

    public static var requestHeaderFieldsTooLarge: ClientError {
        return ClientError.requestHeaderFieldsTooLarge(headers: [:], body: .buffer(Buffer()))
    }
}

extension HTTPError {
    public static func badRequest(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.badRequest(headers: headers, body: .buffer(body.buffer))
    }

    public static func unauthorized(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.unauthorized(headers: headers, body: .buffer(body.buffer))
    }

    public static func paymentRequired(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.paymentRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func forbidden(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.forbidden(headers: headers, body: .buffer(body.buffer))
    }

    public static func notFound(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.notFound(headers: headers, body: .buffer(body.buffer))
    }

    public static func methodNotAllowed(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.methodNotAllowed(headers: headers, body: .buffer(body.buffer))
    }

    public static func notAcceptable(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.notAcceptable(headers: headers, body: .buffer(body.buffer))
    }

    public static func proxyAuthenticationRequired(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.proxyAuthenticationRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestTimeout(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.requestTimeout(headers: headers, body: .buffer(body.buffer))
    }

    public static func conflict(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.conflict(headers: headers, body: .buffer(body.buffer))
    }

    public static func gone(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.gone(headers: headers, body: .buffer(body.buffer))
    }

    public static func lengthRequired(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.lengthRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func preconditionFailed(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.preconditionFailed(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestEntityTooLarge(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.requestEntityTooLarge(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestURITooLong(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.requestURITooLong(headers: headers, body: .buffer(body.buffer))
    }

    public static func unsupportedMediaType(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.unsupportedMediaType(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestedRangeNotSatisfiable(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.requestedRangeNotSatisfiable(headers: headers, body: .buffer(body.buffer))
    }

    public static func expectationFailed(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.expectationFailed(headers: headers, body: .buffer(body.buffer))
    }

    public static func imATeapot(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.imATeapot(headers: headers, body: .buffer(body.buffer))
    }

    public static func authenticationTimeout(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.authenticationTimeout(headers: headers, body: .buffer(body.buffer))
    }

    public static func enhanceYourCalm(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.enhanceYourCalm(headers: headers, body: .buffer(body.buffer))
    }

    public static func unprocessableEntity(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.unprocessableEntity(headers: headers, body: .buffer(body.buffer))
    }

    public static func locked(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.locked(headers: headers, body: .buffer(body.buffer))
    }

    public static func failedDependency(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.failedDependency(headers: headers, body: .buffer(body.buffer))
    }

    public static func preconditionRequired(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.preconditionRequired(headers: headers, body: .buffer(body.buffer))
    }

    public static func tooManyRequests(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
        return ClientError.tooManyRequests(headers: headers, body: .buffer(body.buffer))
    }

    public static func requestHeaderFieldsTooLarge(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ClientError {
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

extension ServerError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case let .internalServerError(headers, body):
            return Response(status: .internalServerError, headers: headers, body: body)
        case let .notImplemented(headers, body):
            return Response(status: .notImplemented, headers: headers, body: body)
        case let .badGateway(headers, body):
            return Response(status: .badGateway, headers: headers, body: body)
        case let .serviceUnavailable(headers, body):
            return Response(status: .serviceUnavailable, headers: headers, body: body)
        case let .gatewayTimeout(headers, body):
            return Response(status: .gatewayTimeout, headers: headers, body: body)
        case let .httpVersionNotSupported(headers, body):
            return Response(status: .httpVersionNotSupported, headers: headers, body: body)
        case let .variantAlsoNegotiates(headers, body):
            return Response(status: .variantAlsoNegotiates, headers: headers, body: body)
        case let .insufficientStorage(headers, body):
            return Response(status: .insufficientStorage, headers: headers, body: body)
        case let .loopDetected(headers, body):
            return Response(status: .loopDetected, headers: headers, body: body)
        case let .notExtended(headers, body):
            return Response(status: .notExtended, headers: headers, body: body)
        case let .networkAuthenticationRequired(headers, body):
            return Response(status: .networkAuthenticationRequired, headers: headers, body: body)
        }
    }
}

extension HTTPError {
    public static var internalServerError: ServerError {
        return ServerError.internalServerError(headers: [:], body: .buffer(Buffer()))
    }

    public static var notImplemented: ServerError {
        return ServerError.notImplemented(headers: [:], body: .buffer(Buffer()))
    }

    public static var badGateway: ServerError {
        return ServerError.badGateway(headers: [:], body: .buffer(Buffer()))
    }

    public static var serviceUnavailable: ServerError {
        return ServerError.serviceUnavailable(headers: [:], body: .buffer(Buffer()))
    }

    public static var gatewayTimeout: ServerError {
        return ServerError.gatewayTimeout(headers: [:], body: .buffer(Buffer()))
    }

    public static var httpVersionNotSupported: ServerError {
        return ServerError.httpVersionNotSupported(headers: [:], body: .buffer(Buffer()))
    }

    public static var variantAlsoNegotiates: ServerError {
        return ServerError.variantAlsoNegotiates(headers: [:], body: .buffer(Buffer()))
    }

    public static var insufficientStorage: ServerError {
        return ServerError.insufficientStorage(headers: [:], body: .buffer(Buffer()))
    }

    public static var loopDetected: ServerError {
        return ServerError.loopDetected(headers: [:], body: .buffer(Buffer()))
    }

    public static var notExtended: ServerError {
        return ServerError.notExtended(headers: [:], body: .buffer(Buffer()))
    }

    public static var networkAuthenticationRequired: ServerError {
        return ServerError.networkAuthenticationRequired(headers: [:], body: .buffer(Buffer()))
    }
}

extension HTTPError {
    public static func internalServerError(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.internalServerError(headers: headers, body: .buffer(body.buffer))
    }

    public static func notImplemented(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.notImplemented(headers: headers, body: .buffer(body.buffer))
    }

    public static func badGateway(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.badGateway(headers: headers, body: .buffer(body.buffer))
    }

    public static func serviceUnavailable(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.serviceUnavailable(headers: headers, body: .buffer(body.buffer))
    }

    public static func gatewayTimeout(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.gatewayTimeout(headers: headers, body: .buffer(body.buffer))
    }

    public static func httpVersionNotSupported(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.httpVersionNotSupported(headers: headers, body: .buffer(body.buffer))
    }

    public static func variantAlsoNegotiates(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.variantAlsoNegotiates(headers: headers, body: .buffer(body.buffer))
    }

    public static func insufficientStorage(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.insufficientStorage(headers: headers, body: .buffer(body.buffer))
    }

    public static func loopDetected(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.loopDetected(headers: headers, body: .buffer(body.buffer))
    }

    public static func notExtended(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.notExtended(headers: headers, body: .buffer(body.buffer))
    }

    public static func networkAuthenticationRequired(headers: Headers = [:], body: BufferRepresentable = Buffer()) -> ServerError {
        return ServerError.networkAuthenticationRequired(headers: headers, body: .buffer(body.buffer))
    }
}
