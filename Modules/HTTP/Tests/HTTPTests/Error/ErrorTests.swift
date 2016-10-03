import XCTest
@testable import HTTP

let clientErrors: [(ClientError, Response)] = [
    (.badRequest(headers: .empty, body: .empty), Response(status: .badRequest)),
    (.unauthorized(headers: .empty, body: .empty), Response(status: .unauthorized)),
    (.paymentRequired(headers: .empty, body: .empty), Response(status: .paymentRequired)),
    (.forbidden(headers: .empty, body: .empty), Response(status: .forbidden)),
    (.notFound(headers: .empty, body: .empty), Response(status: .notFound)),
    (.methodNotAllowed(headers: .empty, body: .empty), Response(status: .methodNotAllowed)),
    (.notAcceptable(headers: .empty, body: .empty), Response(status: .notAcceptable)),
    (.proxyAuthenticationRequired(headers: .empty, body: .empty), Response(status: .proxyAuthenticationRequired)),
    (.requestTimeout(headers: .empty, body: .empty), Response(status: .requestTimeout)),
    (.conflict(headers: .empty, body: .empty), Response(status: .conflict)),
    (.gone(headers: .empty, body: .empty), Response(status: .gone)),
    (.lengthRequired(headers: .empty, body: .empty), Response(status: .lengthRequired)),
    (.preconditionFailed(headers: .empty, body: .empty), Response(status: .preconditionFailed)),
    (.requestEntityTooLarge(headers: .empty, body: .empty), Response(status: .requestEntityTooLarge)),
    (.requestURITooLong(headers: .empty, body: .empty), Response(status: .requestURITooLong)),
    (.unsupportedMediaType(headers: .empty, body: .empty), Response(status: .unsupportedMediaType)),
    (.requestedRangeNotSatisfiable(headers: .empty, body: .empty), Response(status: .requestedRangeNotSatisfiable)),
    (.expectationFailed(headers: .empty, body: .empty), Response(status: .expectationFailed)),
    (.imATeapot(headers: .empty, body: .empty), Response(status: .imATeapot)),
    (.authenticationTimeout(headers: .empty, body: .empty), Response(status: .authenticationTimeout)),
    (.enhanceYourCalm(headers: .empty, body: .empty), Response(status: .enhanceYourCalm)),
    (.unprocessableEntity(headers: .empty, body: .empty), Response(status: .unprocessableEntity)),
    (.locked(headers: .empty, body: .empty), Response(status: .locked)),
    (.failedDependency(headers: .empty, body: .empty), Response(status: .failedDependency)),
    (.preconditionRequired(headers: .empty, body: .empty), Response(status: .preconditionRequired)),
    (.tooManyRequests(headers: .empty, body: .empty), Response(status: .tooManyRequests)),
    (.requestHeaderFieldsTooLarge(headers: .empty, body: .empty), Response(status: .requestHeaderFieldsTooLarge)),
]

let serverErrors: [(ServerError, Response)] = [
    (.internalServerError(headers: .empty, body: .empty), Response(status: .internalServerError)),
    (.notImplemented(headers: .empty, body: .empty), Response(status: .notImplemented)),
    (.badGateway(headers: .empty, body: .empty), Response(status: .badGateway)),
    (.serviceUnavailable(headers: .empty, body: .empty), Response(status: .serviceUnavailable)),
    (.gatewayTimeout(headers: .empty, body: .empty), Response(status: .gatewayTimeout)),
    (.httpVersionNotSupported(headers: .empty, body: .empty), Response(status: .httpVersionNotSupported)),
    (.variantAlsoNegotiates(headers: .empty, body: .empty), Response(status: .variantAlsoNegotiates)),
    (.insufficientStorage(headers: .empty, body: .empty), Response(status: .insufficientStorage)),
    (.loopDetected(headers: .empty, body: .empty), Response(status: .loopDetected)),
    (.notExtended(headers: .empty, body: .empty), Response(status: .notExtended)),
    (.networkAuthenticationRequired(headers: .empty, body: .empty), Response(status: .networkAuthenticationRequired)),
]

public class ErrorTests : XCTestCase {
    func testError() throws {
        for (error, response) in clientErrors {
            XCTAssertEqual(error.response.statusCode, response.statusCode)
        }

        XCTAssertEqual(HTTPError.badRequest, .badRequest(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.unauthorized, .unauthorized(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.paymentRequired, .paymentRequired(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.forbidden, .forbidden(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.notFound, .notFound(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.methodNotAllowed, .methodNotAllowed(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.notAcceptable, .notAcceptable(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.proxyAuthenticationRequired, .proxyAuthenticationRequired(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.requestTimeout, .requestTimeout(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.conflict, .conflict(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.gone, .gone(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.lengthRequired, .lengthRequired(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.preconditionFailed, .preconditionFailed(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.requestEntityTooLarge, .requestEntityTooLarge(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.requestURITooLong, .requestURITooLong(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.unsupportedMediaType, .unsupportedMediaType(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.requestedRangeNotSatisfiable, .requestedRangeNotSatisfiable(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.expectationFailed, .expectationFailed(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.imATeapot, .imATeapot(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.authenticationTimeout, .authenticationTimeout(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.enhanceYourCalm, .enhanceYourCalm(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.unprocessableEntity, .unprocessableEntity(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.locked, .locked(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.failedDependency, .failedDependency(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.preconditionRequired, .preconditionRequired(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.tooManyRequests, .tooManyRequests(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.requestHeaderFieldsTooLarge, .requestHeaderFieldsTooLarge(headers: .empty, body: .empty))

        XCTAssertEqual(HTTPError.badRequest(body: "Hello!"), .badRequest(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.unauthorized(body: "Hello!"), .unauthorized(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.paymentRequired(body: "Hello!"), .paymentRequired(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.forbidden(body: "Hello!"), .forbidden(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.notFound(body: "Hello!"), .notFound(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.methodNotAllowed(body: "Hello!"), .methodNotAllowed(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.notAcceptable(body: "Hello!"), .notAcceptable(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.proxyAuthenticationRequired(body: "Hello!"), .proxyAuthenticationRequired(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.requestTimeout(body: "Hello!"), .requestTimeout(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.conflict(body: "Hello!"), .conflict(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.gone(body: "Hello!"), .gone(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.lengthRequired(body: "Hello!"), .lengthRequired(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.preconditionFailed(body: "Hello!"), .preconditionFailed(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.requestEntityTooLarge(body: "Hello!"), .requestEntityTooLarge(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.requestURITooLong(body: "Hello!"), .requestURITooLong(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.unsupportedMediaType(body: "Hello!"), .unsupportedMediaType(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.requestedRangeNotSatisfiable(body: "Hello!"), .requestedRangeNotSatisfiable(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.expectationFailed(body: "Hello!"), .expectationFailed(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.imATeapot(body: "Hello!"), .imATeapot(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.authenticationTimeout(body: "Hello!"), .authenticationTimeout(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.enhanceYourCalm(body: "Hello!"), .enhanceYourCalm(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.unprocessableEntity(body: "Hello!"), .unprocessableEntity(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.locked(body: "Hello!"), .locked(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.failedDependency(body: "Hello!"), .failedDependency(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.preconditionRequired(body: "Hello!"), .preconditionRequired(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.tooManyRequests(body: "Hello!"), .tooManyRequests(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.requestHeaderFieldsTooLarge(body: "Hello!"), .requestHeaderFieldsTooLarge(headers: .empty, body: .buffer(Buffer("Hello!"))))

        for (error, response) in serverErrors {
            XCTAssertEqual(error.response.statusCode, response.statusCode)
        }

        XCTAssertEqual(HTTPError.internalServerError, .internalServerError(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.notImplemented, .notImplemented(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.badGateway, .badGateway(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.serviceUnavailable, .serviceUnavailable(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.gatewayTimeout, .gatewayTimeout(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.httpVersionNotSupported, .httpVersionNotSupported(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.variantAlsoNegotiates, .variantAlsoNegotiates(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.insufficientStorage, .insufficientStorage(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.loopDetected, .loopDetected(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.notExtended, .notExtended(headers: .empty, body: .empty))
        XCTAssertEqual(HTTPError.networkAuthenticationRequired, .networkAuthenticationRequired(headers: .empty, body: .empty))

        XCTAssertEqual(HTTPError.internalServerError(body: "Hello!"), .internalServerError(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.notImplemented(body: "Hello!"), .notImplemented(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.badGateway(body: "Hello!"), .badGateway(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.serviceUnavailable(body: "Hello!"), .serviceUnavailable(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.gatewayTimeout(body: "Hello!"), .gatewayTimeout(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.httpVersionNotSupported(body: "Hello!"), .httpVersionNotSupported(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.variantAlsoNegotiates(body: "Hello!"), .variantAlsoNegotiates(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.insufficientStorage(body: "Hello!"), .insufficientStorage(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.loopDetected(body: "Hello!"), .loopDetected(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.notExtended(body: "Hello!"), .notExtended(headers: .empty, body: .buffer(Buffer("Hello!"))))
        XCTAssertEqual(HTTPError.networkAuthenticationRequired(body: "Hello!"), .networkAuthenticationRequired(headers: .empty, body: .buffer(Buffer("Hello!"))))
    }
}

extension ErrorTests {
    public static var allTests: [(String, (ErrorTests) -> () throws -> Void)] {
        return [
            ("testError", testError),
        ]
    }
}
