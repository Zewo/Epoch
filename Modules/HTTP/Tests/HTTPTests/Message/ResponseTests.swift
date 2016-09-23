import XCTest
@testable import HTTP

public class ResponseTests : XCTestCase {
    func testCreation() throws {
        var response = Response()
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.version, Version(major: 1, minor: 1))
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))

        response = Response(body: Drain(buffer: "foo") as Core.InputStream)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.version, Version(major: 1, minor: 1))
        XCTAssertEqual(response.headers, ["Transfer-Encoding": "chunked"])
        XCTAssertTrue(response.body.isReader)

        response = Response { stream in
            try stream.write("foo")
            try stream.flush()
        }
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.version, Version(major: 1, minor: 1))
        XCTAssertEqual(response.headers, ["Transfer-Encoding": "chunked"])
        XCTAssertTrue(response.body.isWriter)

        let body = ""
        response = Response(body: body)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.version, Version(major: 1, minor: 1))
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))
    }

    func testStatusAccessors() throws {
        let response = Response(status: .ok)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.reasonPhrase, "OK")
    }

    func testCookieHeader() throws {
        var response = Response()
        response.cookieHeaders = ["foo=bar"]
        XCTAssertEqual(response.cookies, [AttributedCookie(name: "foo", value: "bar")])
        response.cookies = [AttributedCookie(name: "fuu", value: "baz")]
        XCTAssertEqual(response.cookieHeaders, ["fuu=baz"])
        response.cookieHeaders = ["foo"]
        XCTAssertEqual(response.cookies, [])
    }

    func testUpgradeConnection() throws {
        var called = false
        var response = Response()
        response.upgradeConnection { (request, stream) in
            called = true
        }
        try response.upgradeConnection?(Request(), Drain())
        XCTAssert(called)
    }

    func testDescription() throws {
        let response = Response()
        XCTAssertEqual(response.statusLineDescription, "HTTP/1.1 200 OK\n")
        XCTAssertEqual(String(describing: response), "HTTP/1.1 200 OK\nContent-Length: 0\n")
        XCTAssertEqual(response.debugDescription, "HTTP/1.1 200 OK\nContent-Length: 0\n\nStorage:\n-")
    }
}

extension ResponseTests {
    public static var allTests: [(String, (ResponseTests) -> () throws -> Void)] {
        return [
            ("testCreation", testCreation),
            ("testStatusAccessors", testStatusAccessors),
            ("testCookieHeader", testCookieHeader),
            ("testUpgradeConnection", testUpgradeConnection),
            ("testDescription", testDescription),
        ]
    }
}
