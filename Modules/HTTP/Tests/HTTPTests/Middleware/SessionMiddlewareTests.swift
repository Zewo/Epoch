import XCTest
@testable import HTTP

public class SessionMiddlewareTests : XCTestCase {
    let middleware = SessionMiddleware()

    func testCookieIsAdded() throws {
        let request = Request()

        let response = try middleware.respond(to: request, chainingTo: BasicResponder { request in
            XCTAssertNotNil(request.session)
            return Response()
        })

        XCTAssertEqual(response.cookieHeaders.count, 1)
    }

    func testSessionPersists() throws {
        let request1 = Request()
        var request2: Request!

        let response1 = try middleware.respond(to: request1, chainingTo: BasicResponder { req in
            request2 = req
            return Response()
        })

        let session1 = request2.rawSession
        XCTAssertNotNil(session1)
        XCTAssertEqual(response1.cookieHeaders.count, 1)

        let sessionToken = session1.token
        session1.storage["key"] = "value"

        guard let responseCookie = response1.cookies.first else {
            return XCTFail("Response should contain cookie")
        }

        // make another request, this time with the cookie
        var request3 = Request(headers: ["Cookies": response1.cookies.first!.value])
        request3.cookies.insert(Cookie(name: responseCookie.name, value: responseCookie.value))
        var request4: Request!

        let _ = try middleware.respond(to: request3, chainingTo: BasicResponder { req in
            request4 = req
            return Response()
        })

        // make sure session is still there
        let session2 = request4.rawSession
        XCTAssertNotNil(session2)

        // make sure its the same session
        XCTAssertEqual(session2.token, sessionToken)

        // make sure that the session persists information
        try XCTAssertEqual(session2.storage.get("key"), "value")
    }
}

extension SessionMiddlewareTests {
    public static var allTests: [(String, (SessionMiddlewareTests) -> () throws -> Void)] {
        return [
           ("testCookieIsAdded", testCookieIsAdded),
           ("testSessionPersists", testSessionPersists)
        ]
    }
}
