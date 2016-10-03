import XCTest
@testable import Axis
@testable import HTTP

public class HTTPSerializerTests : XCTestCase {
    func testResponseSerializeBuffer() throws {
        let outStream = BufferStream()
        let serializer = ResponseSerializer(stream: outStream)
        var response = Response(body: "foo")
        response.cookies = [AttributedCookie(name: "foo", value: "bar")]

        try serializer.serialize(response, deadline: 1.second.fromNow())
        XCTAssertEqual(outStream.buffer, Buffer("HTTP/1.1 200 OK\r\nContent-Length: 3\r\nSet-Cookie: foo=bar\r\n\r\nfoo"))
    }

    func testResponseSerializeReaderStream() throws {
        let inStream = BufferStream(buffer: Buffer("foo"))
        let outStream = BufferStream()
        let serializer = ResponseSerializer(stream: outStream)
        let response = Response(body: inStream)

        try serializer.serialize(response, deadline: 1.second.fromNow())
        XCTAssertEqual(outStream.buffer, Buffer("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testResponseSerializeWriterStream() throws {
        let outStream = BufferStream()
        let serializer = ResponseSerializer(stream: outStream)

        let response = Response(body: { stream in
            try stream.write("foo", deadline: 1.second.fromNow())
            try stream.flush(deadline: 1.second.fromNow())
        })

        try serializer.serialize(response, deadline: 1.second.fromNow())
        XCTAssertEqual(outStream.buffer, Buffer("HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testRequestSerializeBuffer() throws {
        let outStream = BufferStream()
        let serializer = RequestSerializer(stream: outStream)
        let request = Request(body: "foo")

        try serializer.serialize(request, deadline: 1.second.fromNow())
        XCTAssertEqual(outStream.buffer, Buffer("GET / HTTP/1.1\r\nContent-Length: 3\r\n\r\nfoo"))
    }

    func testRequestSerializeReaderStream() throws {
        let inStream = BufferStream(buffer: "foo")
        let outStream = BufferStream()
        let serializer = RequestSerializer(stream: outStream)
        let request = Request(body: inStream)

        try serializer.serialize(request, deadline: 1.second.fromNow())
        XCTAssertEqual(outStream.buffer, Buffer("GET / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testRequestSerializeWriterStream() throws {
        let outStream = BufferStream()
        let serializer = RequestSerializer(stream: outStream)

        let request = Request(body: { stream in
            try stream.write("foo", deadline: 1.second.fromNow())
            try stream.flush(deadline: 1.second.fromNow())
        })

        try serializer.serialize(request, deadline: 1.second.fromNow())
        XCTAssertEqual(outStream.buffer, Buffer("GET / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nfoo\r\n0\r\n\r\n"))
    }

    func testBodyStream() throws {
        let transport = BufferStream()
        let bodyStream = BodyStream(transport)
        bodyStream.close()
        XCTAssertEqual(bodyStream.closed, true)
        do {
            try bodyStream.write([1, 2, 3], deadline: 1.second.fromNow())
            try bodyStream.flush(deadline: 1.second.fromNow())
            XCTFail()
        } catch {}
        bodyStream.closed = false
        XCTAssertThrowsError(try bodyStream.read(upTo: 1, deadline: 1.second.fromNow()))
    }
}

extension HTTPSerializerTests {
    public static var allTests: [(String, (HTTPSerializerTests) -> () throws -> Void)] {
        return [
            ("testResponseSerializeBuffer", testResponseSerializeBuffer),
            ("testResponseSerializeBuffer", testResponseSerializeReaderStream),
            ("testResponseSerializeBuffer", testResponseSerializeWriterStream),
            ("testResponseSerializeBuffer", testRequestSerializeBuffer),
            ("testResponseSerializeBuffer", testRequestSerializeReaderStream),
            ("testResponseSerializeBuffer", testRequestSerializeWriterStream),
            ("testResponseSerializeBuffer", testBodyStream),
        ]
    }
}
