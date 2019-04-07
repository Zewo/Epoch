import XCTest
import Media
import HTTP
import Venice
import Zewo

class ServerTest: XCTestCase {
    func testServer() throws {
        let message = "Hello"
        let method: Request.Method = .get
        let uri = "/link"
        let deadline = 1.second.fromNow()
        let server = Server { (request) -> Response in
            XCTAssertEqual(request.method, method)
            XCTAssertEqual(request.uri.path, uri)
            return Response(status: .ok, body: "Hello")
        }
        let coroutine = try Coroutine {
            do {
                try server.start()
            } catch {
                XCTAssertEqual("\(error)", "Operation canceled")
            }
        }
        
        try Coroutine.wakeUp(deadline)
        
        let client = try Client(uri: "http://localhost:8080")
        let request = try Request(method: method, uri: uri, body: message)
        let response = try client.send(request)
        let bufferSize = response.contentLength ?? 0
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: bufferSize, alignment: MemoryLayout<UInt8>.alignment)
        _ = try response.body.convertedToReadable().read(buffer, deadline: .immediately)
        XCTAssertEqual(String(buffer), message)

        coroutine.cancel()

        try Coroutine.wakeUp(10.seconds.fromNow())

    }
}
