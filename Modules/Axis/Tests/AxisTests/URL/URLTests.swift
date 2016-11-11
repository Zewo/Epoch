import XCTest
import Foundation
@testable import Axis

public class URLTests : XCTestCase {
    func testQueryItems() {
        let url = URL(string: "http://zewo.io?a=b&c=d%20e")!
        let queryItems = url.queryItems
        
        //this is weird. If you run `XCTAssertEqual(URLQueryItem, URLQueryItem)`
        //just for Axis, everything works, but for Zewo it does not.
        let v0 = URLQueryItem(name: "a", value: "b")
        let v1 = URLQueryItem(name: "c", value: "d e")
        XCTAssertEqual(queryItems[0].name, v0.name)
        XCTAssertEqual(queryItems[0].value, v0.value)
        XCTAssertEqual(queryItems[1].name, v1.name)
        XCTAssertEqual(queryItems[1].value, v1.value)
    }
}

extension URLTests {
    public static var allTests: [(String, (URLTests) -> () throws -> Void)] {
        return [
            ("testQueryItems", testQueryItems),
        ]
    }
}
