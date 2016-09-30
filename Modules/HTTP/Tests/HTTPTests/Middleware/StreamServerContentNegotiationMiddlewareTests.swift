import XCTest
@testable import HTTP

public class StreamServerContentNegotiationMiddlewareTests : XCTestCase {
    let contentNegotiation = ServerContentNegotiationMiddleware(mediaTypes: [JSON.self, URLEncodedForm.self])

    func testJSONRequestDefaultResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/json; charset=utf-8"
            ],
            body: "{\"foo\":\"bar\"}"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        // Because there was no Accept header we serializer with the first media type in the
        // content negotiation middleware media type list. In this case JSON.
        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.transferEncoding, "chunked")
        let stream = BufferStream()
        switch response.body {
        case .writer(let writer):
            try writer(stream)
            XCTAssertEqual(stream.buffer, Buffer("{\"fuu\":\"baz\"}"))
        default:
            XCTFail()
        }
    }

    func testJSONRequestResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/json; charset=utf-8",
                "Accept": "application/json"
            ],
            body: "{\"foo\":\"bar\"}"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.transferEncoding, "chunked")
        let stream = BufferStream()
        switch response.body {
        case .writer(let writer):
            try writer(stream)
            XCTAssertEqual(stream.buffer, Buffer("{\"fuu\":\"baz\"}"))
        default:
            XCTFail()
        }
    }

    func testJSONRequestURLEncodedFormResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/json; charset=utf-8",
                "Accept": "application/x-www-form-urlencoded"
            ],
            body: "{\"foo\":\"bar\"}"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(response.transferEncoding, "chunked")
        let stream = BufferStream()
        switch response.body {
        case .writer(let writer):
            try writer(stream)
            XCTAssertEqual(stream.buffer, Buffer("fuu=baz"))
        default:
            XCTFail()
        }
    }

    func testURLEncodedFormRequestDefaultResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
            ],
            body: "foo=bar"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        // Because there was no Accept header we serializer with the first media type in the
        // content negotiation middleware media type list. In this case JSON.
        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.transferEncoding, "chunked")
        let stream = BufferStream()
        switch response.body {
        case .writer(let writer):
            try writer(stream)
            XCTAssertEqual(stream.buffer, Buffer("{\"fuu\":\"baz\"}"))
        default:
            XCTFail()
        }
    }

    func testURLEncodedFormRequestResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                "Accept": "application/x-www-form-urlencoded"
            ],
            body: "foo=bar"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(response.transferEncoding, "chunked")
        let stream = BufferStream()
        switch response.body {
        case .writer(let writer):
            try writer(stream)
            XCTAssertEqual(stream.buffer, Buffer("fuu=baz"))
        default:
            XCTFail()
        }
    }

    func testURLEncodedFormRequestJSONResponse() throws {
        let request = Request(
            headers: [
                "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                "Accept": "application/json"
            ],
            body: "foo=bar"
        )

        let responder = BasicResponder { request in
            XCTAssertEqual(request.content, ["foo": "bar"])
            return Response(content: ["fuu": "baz"])
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.transferEncoding, "chunked")
        let stream = BufferStream()
        switch response.body {
        case .writer(let writer):
            try writer(stream)
            XCTAssertEqual(stream.buffer, Buffer("{\"fuu\":\"baz\"}"))
        default:
            XCTFail()
        }
    }
}

extension StreamServerContentNegotiationMiddlewareTests {
    public static var allTests: [(String, (StreamServerContentNegotiationMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testJSONRequestDefaultResponse", testJSONRequestDefaultResponse),
            ("testJSONRequestResponse", testJSONRequestResponse),
            ("testJSONRequestURLEncodedFormResponse", testJSONRequestURLEncodedFormResponse),
            ("testURLEncodedFormRequestDefaultResponse", testURLEncodedFormRequestDefaultResponse),
            ("testURLEncodedFormRequestResponse", testURLEncodedFormRequestResponse),
            ("testURLEncodedFormRequestJSONResponse", testURLEncodedFormRequestJSONResponse),
        ]
    }
}
