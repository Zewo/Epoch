import XCTest
import AxisTests
import FileTests
// import HTTPClientTests
// import HTTPFileTests
import HTTPServerTests
import HTTPTests
import IPTests
// import OpenSSLTests
import POSIXTests
import ReflectionTests
import TCPTests
import UDPTests
import VeniceTests
import WebSocketTests
import WebSocketClientTests
import WebSocketServerTests


var testCases = [
    // POSIX
    testCase(POSIXTests.allTests),
    testCase(EnvironmentTests.allTests),
    testCase(ThreadTests.allTests),
    testCase(LockTests.allTests),
    testCase(RegexTests.allTests),

    // Axis
    testCase(JSONTests.allTests),
    testCase(LoggerTests.allTests),
    testCase(InternalTests.allTests),
    testCase(MapConvertibleTests.allTests),
    testCase(PerformanceTests.allTests),
    testCase(PublicTests.allTests),
    testCase(StringTests.allTests),
    testCase(MapTests.allTests),
    testCase(URLTests.allTests),


    // HTTP
    testCase(RequestContentTests.allTests),
    testCase(ResponseContentTests.allTests),
    testCase(AttributedCookieTests.allTests),
    testCase(BodyTests.allTests),
    testCase(CookieTests.allTests),
    testCase(MessageTests.allTests),

    testCase(ResponseTests.allTests),
    testCase(BasicAuthMiddlewareTests.allTests),
    testCase(BufferClientContentNegotiationMiddlewareTests.allTests),
    testCase(BufferServerContentNegotiationMiddlewareTests.allTests),
    testCase(StreamClientContentNegotiationMiddlewareTests.allTests),
    testCase(StreamServerContentNegotiationMiddlewareTests.allTests),
    testCase(LogMiddlewareTests.allTests),
    testCase(RecoveryMiddlewareTests.allTests),
    testCase(RedirectMiddlewareTests.allTests),
    testCase(SessionMiddlewareTests.allTests),
    testCase(RequestParserTests.allTests),
    testCase(ResponseParserTests.allTests),
    testCase(ResourceTests.allTests),
    testCase(RouterTests.allTests),
    testCase(RoutesTests.allTests),
    testCase(TrieRouteMatcherTests.allTests),
    testCase(HTTPSerializerTests.allTests),
    testCase(ServerTests.allTests),

    testCase(UDPSocketTests.allTests),

    // Venice
    testCase(CoroutineTests.allTests),
    testCase(ChannelTests.allTests),
    testCase(FallibleChannelTests.allTests),
    testCase(FileTests.allTests),
    testCase(IPTests.allTests),
    testCase(SelectTests.allTests),
    testCase(TCPTests.allTests),
    testCase(TickerTests.allTests),
    testCase(TimerTests.allTests),

    // WebSocket
    testCase(FrameTests.allTests),
    testCase(SHA1Tests.allTests),
    testCase(WebSocketTests.allTests),
    // WebSocketClient
    testCase(WebSocketClientTests.allTests),
    // WebSocketServer
    testCase(WebSocketServerTests.allTests),
]

#if os(macOS)
testCases += [
    testCase(RequestTests.allTests),
]
#endif

XCTMain(testCases)
