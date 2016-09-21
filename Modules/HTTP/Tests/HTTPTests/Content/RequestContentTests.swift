import XCTest
@testable import HTTP

struct Foo : MapFallibleRepresentable {
    let content: Map
    func asMap() throws -> Map {
        return content
    }
}

public class RequestContentTests : XCTestCase {
    func testContent() throws {
        let content = 1969
        let request = Request(content: content)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testOptionalContent() throws {
        let content: Int? = 1969
        let request = Request(content: content)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testArrayContent() throws {
        let content = [1969]
        let request = Request(content: content)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testDictionaryContent() throws {
        let content = ["Woodstock": 1969]
        let request = Request(content: content)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testFallibleContent() throws {
        let content = 1969
        let foo = Foo(content: 1969)
        let request = try Request(content: foo)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testContentStringURL() throws {
        let content = 1969
        guard let request = Request(url: "/", content: content) else {
            return XCTFail()
        }
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testOptionalContentStringURL() throws {
        let content: Int? = 1969
        guard let request = Request(url: "/", content: content) else {
            return XCTFail()
        }
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testArrayContentStringURL() throws {
        let content = [1969]
        guard let request = Request(url: "/", content: content) else {
            return XCTFail()
        }
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testDictionaryContentStringURL() throws {
        let content = ["Woodstock": 1969]
        guard let request = Request(url: "/", content: content) else {
            return XCTFail()
        }
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }

    func testFallibleContentStringURL() throws {
        let content = 1969
        let foo = Foo(content: 1969)
        let request = try Request(url: "/", content: foo)
        XCTAssertEqual(request.method, .get)
        XCTAssertEqual(request.url.path, "/")
        XCTAssertEqual(request.headers, ["Content-Length": "0"])
        XCTAssertEqual(request.body, .buffer(Buffer()))
        XCTAssertEqual(request.content, Map(content))
    }
}

extension RequestContentTests {
    public static var allTests: [(String, (RequestContentTests) -> () throws -> Void)] {
        return [
            ("testContent", testContent),
            ("testOptionalContent", testOptionalContent),
            ("testArrayContent", testArrayContent),
            ("testDictionaryContent", testDictionaryContent),
            ("testFallibleContent", testFallibleContent),
            ("testContentStringURL", testContentStringURL),
            ("testOptionalContentStringURL", testOptionalContentStringURL),
            ("testArrayContentStringURL", testArrayContentStringURL),
            ("testDictionaryContentStringURL", testDictionaryContentStringURL),
            ("testFallibleContentStringURL", testFallibleContentStringURL),
        ]
    }
}
