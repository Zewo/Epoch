import XCTest
@testable import HTTP

struct Fuu : MapFallibleRepresentable {
    let content: Map
    func asMap() throws -> Map {
        return content
    }
}

public class ResponseContentTests : XCTestCase {
    func testContent() throws {
        let content = 1969
        let response = Response(content: content)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))
        XCTAssertEqual(response.content, Map(content))
    }

    func testOptionalContent() throws {
        let content: Int? = 1969
        let response = Response(content: content)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))
        XCTAssertEqual(response.content, Map(content))
    }

    func testArrayContent() throws {
        let content = [1969]
        let response = Response(content: content)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))
        XCTAssertEqual(response.content, Map(content))
    }

    func testDictionaryContent() throws {
        let content = ["Woodstock": 1969]
        let response = Response(content: content)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))
        XCTAssertEqual(response.content, Map(content))
    }

    func testFallibleContent() throws {
        let content = 1969
        let fuu = Fuu(content: 1969)
        let response = try Response(content: fuu)
        XCTAssertEqual(response.status, .ok)
        XCTAssertEqual(response.headers, ["Content-Length": "0"])
        XCTAssertEqual(response.body, .buffer(Buffer()))
        XCTAssertEqual(response.content, Map(content))
    }
}

extension ResponseContentTests {
    public static var allTests: [(String, (ResponseContentTests) -> () throws -> Void)] {
        return [
            ("testContent", testContent),
            ("testOptionalContent", testOptionalContent),
            ("testArrayContent", testArrayContent),
            ("testDictionaryContent", testDictionaryContent),
            ("testFallibleContent", testFallibleContent),
        ]
    }
}
