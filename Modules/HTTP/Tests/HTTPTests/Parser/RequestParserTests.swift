import XCTest
@testable import HTTP
import CHTTPParser

let requestCount = [
    1,
    2,
    5
]

let bufferSizes = [
    1,
    2,
    4,
    32,
    512,
    2048
]

let methods: [Request.Method] = [
    .delete,
    .get,
    .head,
    .post,
    .put,
    .options,
    .trace,
    .patch,
    .other(method: "COPY"),
    .other(method: "LOCK"),
    .other(method: "MKCOL"),
    .other(method: "MOVE"),
    .other(method: "PROPFIND"),
    .other(method: "PROPPATCH"),
    .other(method: "SEARCH"),
    .other(method: "UNLOCK"),
    .other(method: "BIND"),
    .other(method: "REBIND"),
    .other(method: "UNBIND"),
    .other(method: "ACL"),
    .other(method: "REPORT"),
    .other(method: "MKACTIVITY"),
    .other(method: "CHECKOUT"),
    .other(method: "MERGE"),
    .other(method: "M-SEARCH"),
    .other(method: "NOTIFY"),
    .other(method: "SUBSCRIBE"),
    .other(method: "UNSUBSCRIBE"),
    .other(method: "PURGE"),
    .other(method: "MKCALENDAR"),
    .other(method: "LINK"),
    .other(method: "UNLINK"),
]

public class RequestParserTests : XCTestCase {
    func testInvalidMethod() {
        let data = "INVALID / HTTP/1.1\r\n\r\n"
        let parser = MessageParser(mode: .request)
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testInvalidURL() {
        let data = "GET huehue HTTP/1.1\r\n\r\n"
        let parser = MessageParser(mode: .request)
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testNoURL() {
        let data = "GET HTTP/1.1\r\n\r\n"
        let parser = MessageParser(mode: .request)
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testInvalidHTTPVersion() {
        let data = "GET / HUEHUE\r\n\r\n"
        let parser = MessageParser(mode: .request)
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testInvalidDoubleConnectMethod() {
        let data = "CONNECT / HTTP/1.1\r\n\r\nCONNECT / HTTP/1.1\r\n\r\n"
        let parser = MessageParser(mode: .request)
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testConnectMethod() throws {
        let data = "CONNECT / HTTP/1.1\r\n\r\n"
        let parser = MessageParser(mode: .request)
        let request = try parser.parse(data).first! as! Request
        XCTAssert(request.method == .connect)
        XCTAssert(request.url.path == "/")
        XCTAssert(request.version.major == 1)
        XCTAssert(request.version.minor == 1)
        XCTAssertEqual(request.headers.count, 0)
    }

    func check(request: String, count: Int, bufferSize: Int, test: @escaping (Request) -> Void) throws {
        var data = ""

        for _ in 0 ..< count {
            data += request
        }

        let parser = MessageParser(mode: .request)
        for message in try parser.parse(data) {
            let request = message as! Request
            test(request)
        }
    }

    func testShortRequests() throws {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\n\r\n"
                    try check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.url.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers.count == 0)
                    }
                }
            }
        }
    }

    func testMediumRequests() throws {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nHost: zewo.co\r\n\r\n"
                    try check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.url.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["Host"] == "zewo.co")
                    }
                }
            }
        }
    }

    func testCookiesRequest() throws {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nHost: zewo.co\r\nCookie: server=zewo, lang=swift\r\n\r\n"
                    try check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.url.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["Host"] == "zewo.co")
                        XCTAssert(request.headers["Cookie"] == "server=zewo, lang=swift")
                    }
                }
            }
        }
    }

    func testBodyRequest() throws {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nContent-Length: 4\r\n\r\nZewo"
                    try check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.url.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["Content-Length"] == "4")
                        XCTAssert(request.body == .buffer(Buffer("Zewo")))
                    }
                }
            }
        }
    }

    func testManyRequests() {
        var request = ""

        for _ in 0 ..< 100 {
            request += "POST / HTTP/1.1\r\nContent-Length: 4\r\n\r\nZewo"
        }

        measure {
            do {
                try self.check(request: request, count: 1, bufferSize: 4096) { request in
                    XCTAssert(request.method == .post)
                    XCTAssert(request.url.path == "/")
                    XCTAssert(request.version.major == 1)
                    XCTAssert(request.version.minor == 1)
                    XCTAssert(request.headers["Content-Length"] == "4")
                    XCTAssert(request.body == .buffer(Buffer("Zewo")))
                }
            } catch {
                XCTFail()
            }
        }
    }

    func testErrorDescription() {
        XCTAssertEqual(String(describing: HPE_OK), "success")
    }

    func testUnknownMethod() {
        XCTAssertEqual(Request.Method(code: http_method(rawValue: 1969)), .other(method: "UNKNOWN"))
    }

    func testDuplicateHeaders() throws {
        for bufferSize in bufferSizes {
            for count in requestCount {
                for method in methods {
                    let request = "\(method) / HTTP/1.1\r\nX-Custom-Header: foo\r\nX-Custom-Header: bar\r\n\r\n"
                    try check(request: request, count: count, bufferSize: bufferSize) { request in
                        XCTAssert(request.method == method)
                        XCTAssert(request.url.path == "/")
                        XCTAssert(request.version.major == 1)
                        XCTAssert(request.version.minor == 1)
                        XCTAssert(request.headers["X-Custom-Header"] == "foo, bar")
                    }
                }
            }
        }
    }

    func testChunkedTransferEncodingBody() throws {
        let data = "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n5\r\nHello\r\n0\r\n\r\n"
        let parser = MessageParser(mode: .request)
        let request = try parser.parse(data).first! as! Request
        XCTAssert(request.method == .post)
        XCTAssert(request.url.path == "/")
        XCTAssert(request.version.major == 1)
        XCTAssert(request.version.minor == 1)
        XCTAssertEqual(request.headers.count, 1)
        XCTAssertEqual(request.transferEncoding, "chunked")
    }
}

extension RequestParserTests {
    public static var allTests: [(String, (RequestParserTests) -> () throws -> Void)] {
        return [
            ("testInvalidMethod", testInvalidMethod),
            ("testInvalidURL", testInvalidURL),
            ("testNoURL", testNoURL),
            ("testInvalidHTTPVersion", testInvalidHTTPVersion),
            ("testInvalidDoubleConnectMethod", testInvalidDoubleConnectMethod),
            ("testConnectMethod", testConnectMethod),
            ("testShortRequests", testShortRequests),
            ("testMediumRequests", testMediumRequests),
            ("testCookiesRequest", testCookiesRequest),
            ("testBodyRequest", testBodyRequest),
            ("testManyRequests", testManyRequests),
            ("testErrorDescription", testErrorDescription),
            ("testUnknownMethod", testUnknownMethod),
            ("testDuplicateHeaders", testDuplicateHeaders),
        ]
    }
}
