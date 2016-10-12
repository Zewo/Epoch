import XCTest
@testable import WebSocketTests

XCTMain([
    testCase(FrameTests.allTests),
    testCase(SHA1Tests.allTests),
    testCase(WebSocketTests.allTests),
])
