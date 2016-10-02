import XCTest
@testable import HTTP

public class RequestTests : XCTestCase {
    func testCreation() throws {
        var request = Request()
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .empty)

        request = Request(body: BufferStream(buffer: "foo"))
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Transfer-Encoding": "chunked"])
        XCTAssertTrue(request.body.isReader)

        request = Request { stream in
            try stream.write("foo", deadline: 1.second.fromNow())
            try stream.flush(deadline: 1.second.fromNow())
        }
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Transfer-Encoding": "chunked"])
        XCTAssertTrue(request.body.isWriter)

        let body = ""
        request = Request(body: body)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .empty)

        request = Request(url: "/")!
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .empty)

        request = Request(url: "/", body: BufferStream(buffer: "foo"))!
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Transfer-Encoding": "chunked"])
        XCTAssertTrue(request.body.isReader)

        request = Request(url: "/") { stream in
            try stream.write("foo", deadline: 1.second.fromNow())
            try stream.flush(deadline: 1.second.fromNow())
        }!
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url, URL(string: "/"))
        XCTAssertEqual(request.version, Version(major: 1, minor: 1))
        XCTAssertEqual(request.headers, ["Transfer-Encoding": "chunked"])
        XCTAssertTrue(request.body.isWriter)
    }

    func testURLAccessors() throws {
        let request = Request(url: "/foo?bar=baz")!
        XCTAssertEqual(request.path, "/foo")
        XCTAssertEqual(request.queryItems, [URLQueryItem(name: "bar", value: "baz")])
    }

    func testAcceptHeader() throws {
        var request = Request(headers: ["Accept": "application/json"])
        XCTAssertEqual(request.accept, [MediaType(type: "application", subtype: "json")])
        request.accept = [MediaType(type: "text", subtype: "html")]
        XCTAssertEqual(request.headers["Accept"], "text/html")
    }

    func testCookieHeader() throws {
        var request = Request(headers: ["Cookie": "foo=bar"])
        XCTAssertEqual(request.cookies, [Cookie(name: "foo", value: "bar")])
        request.cookies = [Cookie(name: "fuu", value: "baz")]
        XCTAssertEqual(request.headers["Cookie"], "fuu=baz")
        request.headers["Cookie"] = "foo"
        XCTAssertEqual(request.cookies, [])
    }

    func testHostHeader() {
        var request = Request(headers: ["Host": "foo"])
        XCTAssertEqual(request.host, "foo")
        request.host = "bar"
        XCTAssertEqual(request.headers["Host"], "bar")
        XCTAssertEqual(request.host, "bar")
    }

    func testUserAgentHeader() {
        var request = Request(headers: ["User-Agent": "foo"])
        XCTAssertEqual(request.userAgent, "foo")
        request.userAgent = "bar"
        XCTAssertEqual(request.headers["User-Agent"], "bar")
        XCTAssertEqual(request.userAgent, "bar")
    }

    func testAuthorizationHeader() {
        var request = Request(headers: ["Authorization": "foo"])
        XCTAssertEqual(request.authorization, "foo")
        request.authorization = "bar"
        XCTAssertEqual(request.headers["Authorization"], "bar")
        XCTAssertEqual(request.authorization, "bar")
    }

    func testUpgradeConnection() throws {
        var called = false
        var request = Request()
        request.upgradeConnection { (response, stream) in
            called = true
        }
        try request.upgradeConnection?(Response(), BufferStream())
        XCTAssert(called)
    }

    func testPathParameters() throws {
        var request = Request()
        request.pathParameters = ["foo": "bar"]
        XCTAssertEqual(request.pathParameters, ["foo": "bar"])
    }

    func testDescription() throws {
        let request = Request()
        XCTAssertEqual(request.requestLineDescription, "GET / HTTP/1.1\n")
        XCTAssertEqual(String(describing: request), "GET / HTTP/1.1\nContent-Length: 0\n")
        XCTAssertEqual(request.debugDescription, "GET / HTTP/1.1\nContent-Length: 0\n\nStorage:\n-")
    }
}

extension RequestTests {
    public static var allTests: [(String, (RequestTests) -> () throws -> Void)] {
        return [
            ("testCreation", testCreation),
            ("testCreation", testURLAccessors),
            ("testCreation", testAcceptHeader),
            ("testCreation", testCookieHeader),
            ("testCreation", testHostHeader),
            ("testCreation", testUserAgentHeader),
            ("testCreation", testAuthorizationHeader),
            ("testCreation", testUpgradeConnection),
            ("testCreation", testPathParameters),
            ("testCreation", testDescription),
        ]
    }
}
