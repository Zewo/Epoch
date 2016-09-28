import XCTest
@testable import WebSocketClient

public class WebSocketClientTests: XCTestCase {
    func testReality() {
        XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
    }
}

extension WebSocketClientTests {
    static var allTests: [(String, (WebSocketClientTests) -> () throws -> Void)] {
        return [
           ("testReality", testReality),
        ]
    }
}
