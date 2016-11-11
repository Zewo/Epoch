import XCTest
@testable import WebSocket

public class WebSocketTests : XCTestCase {
    func testReality() {
        XCTAssert(2 + 2 == 4, "Something is severely wrong here.")
    }
}

extension WebSocketTests {
    public static var allTests: [(String, (WebSocketTests) -> () throws -> Void)] {
        return [
           ("testReality", testReality),
        ]
    }
}
