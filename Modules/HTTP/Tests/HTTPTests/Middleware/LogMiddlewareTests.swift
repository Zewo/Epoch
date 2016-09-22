import XCTest
@testable import HTTP

public class LogMiddlewareTests : XCTestCase {
    func testLogMiddleware() throws {
        let stream = Drain()
        let log = LogMiddleware(stream: stream)
        let request = Request()

        let responder = BasicResponder { _ in
            return Response()
        }

        _ = try log.respond(to: request, chainingTo: responder)

        XCTAssertEqual(try String(buffer: stream.buffer), "================================================================================\nRequest:\n\nGET / HTTP/1.1\nContent-Length: 0\n\n--------------------------------------------------------------------------------\nResponse:\n\nHTTP/1.1 200 OK\nContent-Length: 0\n\n================================================================================\n")
    }

    func testDebugLogMiddleware() throws {
        let stream = Drain()
        let log = LogMiddleware(debug: true, stream: stream)
        let request = Request()

        let responder = BasicResponder { _ in
            return Response()
        }

        _ = try log.respond(to: request, chainingTo: responder)

        XCTAssertEqual(try String(buffer: stream.buffer), "================================================================================\nRequest:\n\nGET / HTTP/1.1\nContent-Length: 0\n\nStorage:\n-\n--------------------------------------------------------------------------------\nResponse:\n\nHTTP/1.1 200 OK\nContent-Length: 0\n\nStorage:\n-\n================================================================================\n")
    }
}

extension LogMiddlewareTests {
    public static var allTests: [(String, (LogMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testLogMiddleware", testLogMiddleware),
            ("testDebugLogMiddleware", testDebugLogMiddleware),
        ]
    }
}
