import XCTest
@testable import HTTP

public class StreamClientContentNegotiationMiddlewareTests : XCTestCase {
    let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [.json, .urlEncodedForm], mode: .client, serializationMode: .stream)

    func testClientRequestJSONResponse() throws {
        let request = Request(content: ["foo": "bar"])

        let responder = BasicResponder { request in
            XCTAssertEqual(request.headers["Content-Type"], "application/json; charset=utf-8")
            XCTAssertEqual(request.headers["Accept"], "application/json, application/x-www-form-urlencoded")
            XCTAssertEqual(request.transferEncoding, "chunked")
            XCTAssertNil(request.contentLength)

            let stream = BufferStream()
            switch request.body {
            case .writer(let writer):
                try writer(stream)
                XCTAssertEqual(stream.buffer, Buffer("{\"foo\":\"bar\"}"))
            default:
                XCTFail()
            }
            return Response(
                headers: [
                    "Content-Type": "application/json; charset=utf-8",
                ],
                body: "{\"fuu\":\"baz\"}"
            )
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        // Because there was no Accept header we serializer with the first media type in the
        // content negotiation middleware media type list. In this case JSON.
        XCTAssertEqual(response.headers["Content-Type"], "application/json; charset=utf-8")
        XCTAssertEqual(response.content, ["fuu": "baz"])
    }

    func testClientRequestURLEncodedFormResponse() throws {
        let request = Request(content: ["foo": "bar"])

        let responder = BasicResponder { request in
            XCTAssertEqual(request.headers["Content-Type"], "application/json; charset=utf-8")
            XCTAssertEqual(request.headers["Accept"], "application/json, application/x-www-form-urlencoded")
            XCTAssertEqual(request.transferEncoding, "chunked")
            XCTAssertNil(request.contentLength)

            let stream = BufferStream()
            switch request.body {
            case .writer(let writer):
                try writer(stream)
                XCTAssertEqual(stream.buffer, Buffer("{\"foo\":\"bar\"}"))
            default:
                XCTFail()
            }
            return Response(
                headers: [
                    "Content-Type": "application/x-www-form-urlencoded; charset=utf-8",
                ],
                body: "fuu=baz"
            )
        }

        let response = try contentNegotiation.respond(to: request, chainingTo: responder)

        // Because there was no Accept header we serializer with the first media type in the
        // content negotiation middleware media type list. In this case JSON.
        XCTAssertEqual(response.headers["Content-Type"], "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(response.content, ["fuu": "baz"])
    }
}

extension StreamClientContentNegotiationMiddlewareTests {
    public static var allTests: [(String, (StreamClientContentNegotiationMiddlewareTests) -> () throws -> Void)] {
        return [
            ("testClientRequestJSONResponse", testClientRequestJSONResponse),
            ("testClientRequestURLEncodedFormResponse", testClientRequestURLEncodedFormResponse),
        ]
    }
}
