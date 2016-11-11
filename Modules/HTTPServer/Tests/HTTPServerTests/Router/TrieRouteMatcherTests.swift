import XCTest
@testable import HTTPServer

public class TrieRouteMatcherTests : XCTestCase {
    let ok = BasicResponder { request in
        return Response(status: .ok)
    }

    func testTrie() {
        var trie = Trie<Character, Int>()

        trie.insert("12345".characters, payload: 10101)
        trie.insert("12456".characters)
        trie.insert("12346".characters)
        trie.insert("12344".characters)
        trie.insert("92344".characters)

        XCTAssert(trie.contains("12345".characters))
        XCTAssert(trie.contains("92344".characters))
        XCTAssert(!trie.contains("12".characters))
        XCTAssert(!trie.contains("12444".characters))
        XCTAssert(trie.findPayload("12345".characters) == 10101)
        XCTAssert(trie.findPayload("12346".characters) == nil)

        XCTAssertFalse(String(describing: trie).isEmpty)
        XCTAssertEqual(trie, trie)
    }

    func testMatcherMatchesRoutes() {
        let routes: [Route] = [
            Route(path: "/hello/world"),
            Route(path: "/hello/dan"),
            Route(path: "/api/:version"),
            Route(path: "/servers/json"),
            Route(path: "/servers/:host/logs")
        ]

        let matcher = TrieRouteMatcher(routes: routes)

        func route(_ path: String, shouldMatch: Bool) -> Bool {
            let request = Request(method: .get, url: path)!
            let matched = matcher.match(request)
            return shouldMatch ?  matched != nil : matched == nil
        }

        XCTAssert(route("/hello/world", shouldMatch: true))
        XCTAssert(route("/hello/dan", shouldMatch: true))
        XCTAssert(route("/hello/world/dan", shouldMatch: false))
        XCTAssert(route("/api/v1", shouldMatch: true))
        XCTAssert(route("/api/v2", shouldMatch: true))
        XCTAssert(route("/api/v1/v1", shouldMatch: false))
        XCTAssert(route("/api/api", shouldMatch: true))
        XCTAssert(route("/servers/json", shouldMatch: true))
        XCTAssert(route("/servers/notjson", shouldMatch: false))
        XCTAssert(route("/servers/notjson/logs", shouldMatch: true))
        XCTAssert(route("/servers/json/logs", shouldMatch: true))
    }

    func testMatcherWithTrailingSlashes() {
        let routes: [Route] = [
            Route(path: "/hello/world")
        ]

        let matcher = TrieRouteMatcher(routes: routes)

        let request1 = Request(method: .get, url: "/hello/world")!
        let request2 = Request(method: .get, url: "/hello/world/")!

        XCTAssert(matcher.match(request1) != nil)
        XCTAssert(matcher.match(request2) != nil)
    }

    func testMatcherParsesPathParameters() {
        let routes: [Route] = [
            Route(
                path: "/hello/world",
                actions: [
                    .get: BasicResponder { _ in
                        Response(body: "hello world - not!")
                    }
                ]
            ),
            Route(
                path: "/hello/:location",
                actions: [
                    .get: BasicResponder {
                        Response(body: "hello \($0.pathParameters["location"]!)")
                    }
                ]
            ),
            Route(
                path: "/:greeting/:location",
                actions: [
                    .get: BasicResponder {
                        Response(body: "\($0.pathParameters["greeting"]!) \($0.pathParameters["location"]!)")
                    }
                ]
            )
        ]

        let matcher = TrieRouteMatcher(routes: routes)

        func body(with request: Request, is expectedResponse: String) -> Bool {
            guard var body = try? matcher.match(request)?.respond(to: request).body else {
                return false
            }
            guard let buffer = try? body?.becomeBuffer(deadline: 1.second.fromNow()) else {
                return false
            }
            return buffer == expectedResponse.buffer
        }

        let helloWorld = Request(method: .get, url: "/hello/world")!
        let helloAmerica = Request(method: .get, url: "/hello/america")!
        let heyAustralia = Request(method: .get, url: "/hey/australia")!

        XCTAssert(body(with: helloWorld, is: "hello world - not!"))
        XCTAssert(body(with: helloAmerica, is: "hello america"))
        XCTAssert(body(with: heyAustralia, is: "hey australia"))
    }

    func testMatcherReturnsCorrectPathParameters() throws {
        let routePaths = [
            "/hello/:city/a",
            "/hello/:country/b"
        ]

        let routes: [Route] = routePaths.map {
            Route(
                path: $0,
                actions: [
                    .get: BasicResponder { request in
                        var response = Response()
                        response.storage["testPathParameters"] = request.pathParameters
                        return response
                    }
                ]
            )
        }

        let matcher = TrieRouteMatcher(routes: routes)

        let tests: [(path: String, expectation: [String: String])] = [
            ("/hello/venice/a", ["city": "venice"]),
            ("/hello/america/b", ["country": "america"])
        ]

        for (path, expectation) in tests {
            let request = Request(method: .get, url: path)!

            guard let response = try matcher.match(request)?.respond(to: request) else {
                return XCTFail("Match didn't find any route")
            }

            let pathParameters = response.storage["testPathParameters"] as! [String: String]

            XCTAssertEqual(expectation, pathParameters)
        }
    }

    func testMatcherMatchesWildcards() {

        func testRoute(path: String, response: String) -> Route {
            return Route(path: path, actions: [.get: BasicResponder { _ in Response(body: response) }])
        }

        let routes: [Route] = [
            testRoute(path: "/*", response: "wild"),
            testRoute(path: "/hello/*", response: "hello wild"),
            testRoute(path: "/hello/dan", response: "hello dan"),
        ]

        let matcher = TrieRouteMatcher(routes: routes)

        func route(_ path: String, expectedResponse: String) -> Bool {
            let request = Request(method: .get, url: path)!
            let matched = matcher.match(request)

            guard var body = try? matched?.respond(to: request).body else {
                return false
            }
            guard let buffer = try? body?.becomeBuffer(deadline: 1.second.fromNow()) else {
                return false
            }
            return buffer == expectedResponse.buffer
        }

        XCTAssert(route("/", expectedResponse: "wild"))
        XCTAssert(route("/a/s/d/f", expectedResponse: "wild"))
        XCTAssert(route("/hello", expectedResponse: "hello wild"))
        XCTAssert(route("/hello/asdf", expectedResponse: "hello wild"))
        XCTAssert(route("/hello/dan", expectedResponse: "hello dan"))
    }

    func testPerformance() {
        let routePairs: [(Request.Method, String)] = [
            // Objects
            (.post, "/1/classes/:className"),
            (.get, "/1/classes/:className/:objectId"),
            (.put, "/1/classes/:className/:objectId"),
            (.get, "/1/classes/:className"),
            (.delete, "/1/classes/:className/:objectId"),

            // Users
            (.post, "/1/users"),
            (.get, "/1/login"),
            (.get, "/1/users/:objectId"),
            (.put, "/1/users/:objectId"),
            (.get, "/1/users"),
            (.delete, "/1/users/:objectId"),
            (.post, "/1/requestPasswordReset"),

            // Roles
            (.post, "/1/roles"),
            (.get, "/1/roles/:objectId"),
            (.put, "/1/roles/:objectId"),
            (.get, "/1/roles"),
            (.delete, "/1/roles/:objectId"),

            // Files
            (.post, "/1/files/:fileName"),

            // Analytics
            (.post, "/1/events/:eventName"),

            // Push Notifications
            (.post, "/1/push"),

            // Installations
            (.post, "/1/installations"),
            (.get, "/1/installations/:objectId"),
            (.put, "/1/installations/:objectId"),
            (.get, "/1/installations"),
            (.delete, "/1/installations/:objectId"),

            // Cloud Functions
            (.post, "/1/functions"),
            ]

        let requestPairs: [(Request.Method, String)] = [
            // Objects
            (.post, "/1/classes/test"),
            (.get, "/1/classes/test/test"),
            (.put, "/1/classes/test/test"),
            (.get, "/1/classes/test"),
            (.delete, "/1/classes/test/test"),

            // Users
            (.post, "/1/users"),
            (.get, "/1/login"),
            (.get, "/1/users/test"),
            (.put, "/1/users/test"),
            (.get, "/1/users"),
            (.delete, "/1/users/test"),
            (.post, "/1/requestPasswordReset"),

            // Roles
            (.post, "/1/roles"),
            (.get, "/1/roles/test"),
            (.put, "/1/roles/test"),
            (.get, "/1/roles"),
            (.delete, "/1/roles/test"),

            // Files
            (.post, "/1/files/test"),

            // Analytics
            (.post, "/1/events/test"),

            // Push Notifications
            (.post, "/1/push"),

            // Installations
            (.post, "/1/installations"),
            (.get, "/1/installations/test"),
            (.put, "/1/installations/test"),
            (.get, "/1/installations"),
            (.delete, "/1/installations/test"),

            // Cloud Functions
            (.post, "/1/functions"),
        ]

        let routes: [Route] = routePairs.map({ Route(path: $0.1, actions: [$0.0: ok]) })

        let requests = requestPairs.map {
            Request(method: $0.0, url: $0.1)!
        }

        let matcher = TrieRouteMatcher(routes: routes)

        measure {
            for _ in 0...50 {
                for request in requests {
                    XCTAssertNotNil(matcher.match(request))
                }
            }
        }
    }
}

extension TrieRouteMatcherTests {
    public static var allTests: [(String, (TrieRouteMatcherTests) -> () throws -> Void)] {
        return [
            ("testTrie", testTrie),
            ("testMatcherMatchesRoutes", testMatcherMatchesRoutes),
            ("testMatcherWithTrailingSlashes", testMatcherWithTrailingSlashes),
            ("testMatcherParsesPathParameters", testMatcherParsesPathParameters),
            ("testMatcherReturnsCorrectPathParameters", testMatcherReturnsCorrectPathParameters),
            ("testMatcherMatchesWildcards", testMatcherMatchesWildcards),
            ("testPerformance", testPerformance),
        ]
    }
}
