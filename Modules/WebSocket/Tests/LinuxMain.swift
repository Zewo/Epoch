import XCTest
@testable import WebSocketTests

XCTMain([
    testCase(FrameTests.allTests),
    testCase(WebSocketTests.allTests),
])
