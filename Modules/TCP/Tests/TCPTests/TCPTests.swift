import XCTest
@testable import TCP
@testable import Venice

public class TCPTests : XCTestCase {
    func testConnectionRefused() throws {
        let connection = try TCPStream(host: "127.0.0.1", port: 1111, deadline: 1.second.fromNow())
        XCTAssertThrowsError(try connection.open(deadline: 1.second.fromNow()))
    }

    func testWriteClosedSocket() throws {
        let port = 2222

        co {
            do {
                let host = try TCPHost(host: "0.0.0.0", port: port)
                _ = try host.accept(deadline: 1.second.fromNow())
            } catch {
                XCTFail()
            }
        }

        let stream = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try stream.open(deadline: 1.second.fromNow())
        stream.close()
        XCTAssertThrowsError(try stream.write([1, 2, 3], deadline: 1.second.fromNow()))
    }

    func testFlushClosedSocket() throws {
        let port = 3333

        co {
            do {
                let host = try TCPHost(host: "127.0.0.1", port: port)
                _ = try host.accept(deadline: 1.second.fromNow())
            } catch {
                XCTFail()
            }
        }

        let connection = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try connection.open(deadline: 1.second.fromNow())
        connection.close()
        XCTAssertThrowsError(try connection.flush(deadline: 1.second.fromNow()))
    }

    func testReadClosedSocket() throws {
        let port = 4444

        co {
            do {
                let host = try TCPHost(host: "127.0.0.1", port: port)
                _ = try host.accept(deadline: 1.second.fromNow())
            } catch {
                XCTFail()
            }
        }

        let connection = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try connection.open(deadline: 1.second.fromNow())
        connection.close()
        XCTAssertThrowsError(try connection.read(upTo: 1, deadline: 1.second.fromNow()))
    }

    func testWriteRead() throws {
        let port = 5555

        co {
            do {
                let host = try TCPHost(host: "127.0.0.1", port: port)
                let connection = try host.accept(deadline: 1.second.fromNow())
                let buffer = try connection.read(upTo: 1, deadline: 1.second.fromNow())
                XCTAssertEqual(buffer.count, 1)
                XCTAssertEqual(buffer, Buffer([123]))
                connection.close()
            } catch {
                XCTAssert(false)
            }
        }

        let connection = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try connection.open(deadline: 1.second.fromNow())
        try connection.write([123], deadline: 1.second.fromNow())
        try connection.flush(deadline: 1.second.fromNow())
    }

    func testClientServer() throws {
        let port = 6666
        let deadline = 5.seconds.fromNow()
        let done = FallibleChannel<Void>()

        co {
            do {
                let host = try TCPHost(host: "127.0.0.1", port: port)
                let stream = try host.accept(deadline: deadline)

                try stream.write("ABC", deadline: deadline)
                try stream.flush(deadline: deadline)

                let buffer = try stream.read(upTo: 9, deadline: deadline)
                XCTAssertEqual(buffer.count, 9)
                XCTAssertEqual(buffer, Buffer("123456789"))

                done.send()
            } catch {
                done.send(error)
            }
        }

        let stream = try TCPStream(host: "127.0.0.1", port: port, deadline: deadline)
        try stream.open(deadline: deadline)

        let buffer = try stream.read(upTo: 3, deadline: deadline)
        XCTAssertEqual(buffer, Buffer("ABC"))
        XCTAssertEqual(buffer.count, 3)

        try stream.write("123456789", deadline: deadline)
        try stream.flush(deadline: deadline)

        try done.receive()
    }
}

extension TCPTests {
    public static var allTests: [(String, (TCPTests) -> () throws -> Void)] {
        return [
            ("testConnectionRefused", testConnectionRefused),
            ("testWriteClosedSocket", testWriteClosedSocket),
            ("testFlushClosedSocket", testFlushClosedSocket),
            ("testReadClosedSocket", testReadClosedSocket),
            ("testWriteRead", testWriteRead),
            ("testClientServer", testClientServer),
        ]
    }
}
