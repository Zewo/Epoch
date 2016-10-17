import XCTest
import Foundation
@testable import Axis

public class URLTests : XCTestCase {
    func testQueryItems() {
        let url = URL(string: "http://zewo.io?a=b&c=d%20e")!
        let queryItems = url.queryItems
        XCTAssertEqual(queryItems[0], URLQueryItem(name: "a", value: "b"))
        XCTAssertEqual(queryItems[1], URLQueryItem(name: "c", value: "d e"))
    }
}

extension URLTests {
    public static var allTests: [(String, (URLTests) -> () throws -> Void)] {
        return [
            ("testQueryItems", testQueryItems),
        ]
    }
}
