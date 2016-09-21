import XCTest
@testable import HTTP

let responseCount = [
    1,
    2,
    5
]

let statuses: [Response.Status] = [
    .`continue`,
    .switchingProtocols,
    .processing,

    .ok,
    .created,
    .accepted,
    .nonAuthoritativeInformation,
    .noContent,
    .resetContent,
    .partialContent,

    .multipleChoices,
    .movedPermanently,
    .found,
    .seeOther,
    .notModified,
    .useProxy,
    .switchProxy,
    .temporaryRedirect,
    .permanentRedirect,

    .badRequest,
    .unauthorized,
    .paymentRequired,
    .forbidden,
    .notFound,
    .methodNotAllowed,
    .notAcceptable,
    .proxyAuthenticationRequired,
    .requestTimeout,
    .conflict,
    .gone,
    .lengthRequired,
    .preconditionFailed,
    .requestEntityTooLarge,
    .requestURITooLong,
    .unsupportedMediaType,
    .requestedRangeNotSatisfiable,
    .expectationFailed,
    .imATeapot,
    .authenticationTimeout,
    .enhanceYourCalm,
    .unprocessableEntity,
    .locked,
    .failedDependency,
    .preconditionRequired,
    .tooManyRequests,
    .requestHeaderFieldsTooLarge,

    .internalServerError,
    .notImplemented,
    .badGateway,
    .serviceUnavailable,
    .gatewayTimeout,
    .httpVersionNotSupported,
    .variantAlsoNegotiates,
    .insufficientStorage,
    .loopDetected,
    .notExtended,
    .networkAuthenticationRequired,
]

public class ResponseParserTests : XCTestCase {
    func testInvalidHTTPVersion() throws {
        let data = "HUEHUE 200 OK\r\n\r\n"
        let stream = Drain(buffer: data)
        let parser = ResponseParser(stream: stream)
        XCTAssertThrowsError(try parser.parse())
    }

    func check(response: String, count: Int, bufferSize: Int, test: (Response) -> Void) throws {
        var data = ""

        for _ in 0 ..< count {
            data += response
        }

        let stream = Drain(buffer: data)
        let parser = ResponseParser(stream: stream, bufferSize: bufferSize)

        for _ in 0 ..< count {
            try test(parser.parse())
        }
    }

    func testShortResponses() throws {
        for bufferSize in bufferSizes {
            for count in responseCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 0\r\n\r\n"
                    try check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers.count == 1)
                        XCTAssert(response.headers["Content-Length"] == "0")
                    }
                }
            }
        }
    }

    func testCookiesResponse() throws {
        for bufferSize in bufferSizes {
            for count in responseCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 0\r\nHost: zewo.co\r\nSet-Cookie: server=zewo\r\nSet-Cookie: lang=swift\r\n\r\n"
                    try check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers["Host"] == "zewo.co")
                        XCTAssert(response.cookies.contains(AttributedCookie(name: "server", value: "zewo")))
                        XCTAssert(response.cookies.contains(AttributedCookie(name: "lang", value: "swift")))
                    }
                }
            }
        }
    }

    func testBodyResponse() throws {
        for bufferSize in bufferSizes {
            for count in responseCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 4\r\n\r\nZewo"
                    try check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers["Content-Length"] == "4")
                        XCTAssert(response.body == .buffer(Buffer("Zewo")))
                    }
                }
            }
        }
    }

    func testManyResponses() {
        var response = ""

        for _ in 0 ..< 100 {
            response += "HTTP/1.1 200 OK\r\nContent-Length: 4\r\n\r\nZewo"
        }

        measure {
            do {
                try self.check(response: response, count: 1, bufferSize: 4096) { response in
                    XCTAssert(response.status == .ok)
                    XCTAssert(response.version.major == 1)
                    XCTAssert(response.version.minor == 1)
                    XCTAssert(response.headers["Content-Length"] == "4")
                    XCTAssert(response.body == .buffer(Buffer("Zewo")))
                }
            } catch {
                XCTFail()
            }
        }
    }

    func testDuplicateHeaders() throws {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for status in statuses {
                    let response = "HTTP/1.1 \(status.statusCode) \(status.reasonPhrase)\r\nContent-Length: 0\r\nX-Custom-Header: foo\r\nX-Custom-Header: bar\r\n\r\n"
                    try check(response: response, count: count, bufferSize: bufferSize) { response in
                        XCTAssert(response.status == status)
                        XCTAssert(response.version.major == 1)
                        XCTAssert(response.version.minor == 1)
                        XCTAssert(response.headers["X-Custom-Header"] == "foo, bar")
                    }
                }
            }
        }
    }
}

extension ResponseParserTests {
    public static var allTests: [(String, (ResponseParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidHTTPVersion", testInvalidHTTPVersion),
            ("testShortResponses", testShortResponses),
            ("testCookiesResponse", testCookiesResponse),
            ("testBodyResponse", testBodyResponse),
            ("testManyResponses", testManyResponses),
            ("testDuplicateHeaders", testDuplicateHeaders),
        ]
    }
}
