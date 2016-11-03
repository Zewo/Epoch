import XCTest
import HTTPServerTests

XCTMain([
    testCase(ResourceTests.allTests),
    testCase(RouterTests.allTests),
    testCase(RoutesTests.allTests),
    testCase(TrieRouteMatcherTests.allTests),
    testCase(ServerTests.allTests),
])
