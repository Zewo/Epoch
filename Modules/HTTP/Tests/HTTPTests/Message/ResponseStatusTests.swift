import XCTest
@testable import HTTP

let responseStatus: [Response.Status: (Int, String)] = [
    .`continue`: (100, "Continue"),
    .switchingProtocols: (101, "Switching Protocols"),
    .processing: (102, "Processing"),

    .ok: (200, "OK"),
    .created: (201, "Created"),
    .accepted: (202, "Accepted"),
    .nonAuthoritativeInformation: (203, "Non Authoritative Information"),
    .noContent: (204, "No Content"),
    .resetContent: (205, "Reset Content"),
    .partialContent: (206, "Partial Content"),

    .multipleChoices: (300, "Multiple Choices"),
    .movedPermanently: (301, "Moved Permanently"),
    .found: (302, "Found"),
    .seeOther: (303, "See Other"),
    .notModified: (304, "Not Modified"),
    .useProxy: (305, "Use Proxy"),
    .switchProxy: (306, "Switch Proxy"),
    .temporaryRedirect: (307, "Temporary Redirect"),
    .permanentRedirect: (308, "Permanent Redirect"),

    .badRequest: (400, "Bad Request"),
    .unauthorized: (401, "Unauthorized"),
    .paymentRequired: (402, "Payment Required"),
    .forbidden: (403, "Forbidden"),
    .notFound: (404, "Not Found"),
    .methodNotAllowed: (405, "Method Not Allowed"),
    .notAcceptable: (406, "Not Acceptable"),
    .proxyAuthenticationRequired: (407, "Proxy Authentication Required"),
    .requestTimeout: (408, "Request Timeout"),
    .conflict: (409, "Conflict"),
    .gone: (410, "Gone"),
    .lengthRequired: (411, "Length Required"),
    .preconditionFailed: (412, "Precondition Failed"),
    .requestEntityTooLarge: (413, "Request Entity Too Large"),
    .requestURITooLong: (414, "Request URI Too Long"),
    .unsupportedMediaType: (415, "Unsupported Media Type"),
    .requestedRangeNotSatisfiable: (416, "Requested Range Not Satisfiable"),
    .expectationFailed: (417, "Expectation Failed"),
    .imATeapot: (418, "I'm A Teapot"),
    .authenticationTimeout: (419, "Authentication Timeout"),
    .enhanceYourCalm: (420, "Enhance Your Calm"),
    .unprocessableEntity: (422, "Unprocessable Entity"),
    .locked: (423, "Locked"),
    .failedDependency: (424, "Failed Dependency"),
    .preconditionRequired: (428, "Precondition Required"),
    .tooManyRequests: (429, "Too Many Requests"),
    .requestHeaderFieldsTooLarge: (431, "Request Header Fields Too Large"),

    .internalServerError: (500, "Internal Server Error"),
    .notImplemented: (501, "Not Implemented"),
    .badGateway: (502, "Bad Gateway"),
    .serviceUnavailable: (503, "Service Unavailable"),
    .gatewayTimeout: (504, "Gateway Timeout"),
    .httpVersionNotSupported: (505, "HTTP Version Not Supported"),
    .variantAlsoNegotiates: (506, "Variant Also Negotiates"),
    .insufficientStorage: (507, "Insufficient Storage"),
    .loopDetected: (508, "Loop Detected"),
    .notExtended: (510, "Not Extended"),
    .networkAuthenticationRequired: (511, "Network Authentication Required"),

    .other(statusCode: 499, reasonPhrase: "OH NOES"): (499, "OH NOES"),
]

public class ResponseStatusTests : XCTestCase {
    func testStatus() throws {
        for (status, (statusCode, reasonPhrase)) in responseStatus {
            XCTAssertEqual(status, status)
            XCTAssertEqual(status.statusCode, statusCode)
            XCTAssertEqual(status.reasonPhrase, reasonPhrase)
            let newStatus = Response.Status(statusCode: statusCode)
            XCTAssertEqual(newStatus, status)
        }
        let customReasonPhrase = Response.Status(statusCode: 200, reasonPhrase: "OH YEAHS")
        XCTAssertEqual(customReasonPhrase, .other(statusCode: 200, reasonPhrase: "OH YEAHS"))

        XCTAssertTrue(Response.Status.continue.isInformational)
        XCTAssertTrue(Response.Status.ok.isSuccessful)
        XCTAssertTrue(Response.Status.multipleChoices.isRedirection)
        XCTAssertTrue(Response.Status.badRequest.isError)
        XCTAssertTrue(Response.Status.badRequest.isClientError)
        XCTAssertTrue(Response.Status.internalServerError.isError)
        XCTAssertTrue(Response.Status.internalServerError.isServerError)
    }
}

extension ResponseStatusTests {
    public static var allTests: [(String, (ResponseStatusTests) -> () throws -> Void)] {
        return [
            ("testStatus", testStatus),
        ]
    }
}
