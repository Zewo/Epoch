import XCTest
import HTTPTests

XCTMain([
    testCase(RequestContentTests.allTests),
    testCase(ResponseContentTests.allTests),
    testCase(ErrorTests.allTests),
    testCase(AttributedCookieTests.allTests),
    testCase(BodyTests.allTests),
    testCase(CookieTests.allTests),
    testCase(MessageTests.allTests),
    testCase(RequestMethodTests.allTests),
    testCase(RequestTests.allTests),
    testCase(ResponseStatusTests.allTests),
    testCase(ResponseTests.allTests),
    testCase(BasicAuthMiddlewareTests.allTests),
    testCase(BufferClientContentNegotiationMiddlewareTests.allTests),
    testCase(BufferServerContentNegotiationMiddlewareTests.allTests),
    testCase(LogMiddlewareTests.allTests),
    testCase(RecoveryMiddlewareTests.allTests),
    testCase(RedirectMiddlewareTests.allTests),
    testCase(SessionMiddlewareTests.allTests),
    testCase(StreamClientContentNegotiationMiddlewareTests.allTests),
    testCase(StreamServerContentNegotiationMiddlewareTests.allTests),
    testCase(RequestParserTests.allTests),
    testCase(ResponseParserTests.allTests),
    testCase(HTTPSerializerTests.allTests),
])
