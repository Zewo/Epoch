import XCTest
@testable import IO
@testable import Core
@testable import Venice

let deadline: Deadline = .never

public class TCPTests: XCTestCase {
    func testConnectionRefused() throws {
        let connection = try TCPStream(host: "127.0.0.1", port: 1111, deadline: 1.second.fromNow())
        XCTAssertThrowsError(try connection.open(deadline: 1.second.fromNow()))
    }

    func testWriteClosedSocket() throws {
        let port = 2222

        let channel = try Channel<Void>()

        let coroutine = try Coroutine {
            let host = try TCPHost(host: "0.0.0.0", port: port, deadline: deadline)
            _ = try host.accept(deadline: 1.second.fromNow())
            try channel.send(deadline: .never)
        }

        let stream = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try stream.open(deadline: 1.second.fromNow())
        stream.close()
        try channel.receive(deadline: .never)
        try coroutine.cancel()
        XCTAssertThrowsError(try stream.write("123", deadline: 1.second.fromNow()))
    }

    func testFlushClosedSocket() throws {
        let port = 3333

        let channel = try Channel<Void>()

        let coroutine = try Coroutine {
            let host = try TCPHost(host: "127.0.0.1", port: port, deadline: deadline)
            _ = try host.accept(deadline: 1.second.fromNow())
            try channel.send(deadline: .never)
        }

        let connection = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try connection.open(deadline: 1.second.fromNow())
        connection.close()
        try channel.receive(deadline: .never)
        try coroutine.cancel()
        XCTAssertThrowsError(try connection.flush(deadline: 1.second.fromNow()))
    }

    func testReadClosedSocket() throws {
        let port = 4444

        let channel = try Channel<Void>()

        let coroutine = try Coroutine {
            let host = try TCPHost(host: "127.0.0.1", port: port, deadline: deadline)
            _ = try host.accept(deadline: 1.second.fromNow())
            try channel.send(deadline: .never)
        }

        let connection = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try connection.open(deadline: 1.second.fromNow())
        connection.close()
        try channel.receive(deadline: .never)
        try coroutine.cancel()
        let buffer = UnsafeMutableRawBufferPointer(start: nil, count: 0)
        XCTAssertThrowsError(try connection.read(into: buffer, deadline: 1.second.fromNow()))
    }

    func testWriteRead() throws {
        let buffer = UnsafeMutableRawBufferPointer.allocate(count: 1)
        
        defer {
            buffer.deallocate()
        }
        
        let port = 5555

        let channel = try Channel<Void>()

        let coroutine = try Coroutine {
            let host = try TCPHost(host: "127.0.0.1", port: port, deadline: deadline)
            let connection = try host.accept(deadline: 1.second.fromNow())
            let buffer = try connection.read(into: buffer, deadline: 1.second.fromNow())

            XCTAssertEqual(buffer[0], 65)
            connection.close()
            try channel.send(deadline: .never)
        }

        let connection = try TCPStream(host: "127.0.0.1", port: port, deadline: 1.second.fromNow())
        try connection.open(deadline: 1.second.fromNow())
        try connection.write("A", deadline: 1.second.fromNow())
        try connection.flush(deadline: 1.second.fromNow())
        try channel.receive(deadline: .never)
        try coroutine.cancel()
    }

    func testClientServer() throws {
        let buffer = UnsafeMutableRawBufferPointer.allocate(count: 9)
        
        defer {
            buffer.deallocate()
        }
        
        let port = 6666
        let deadline = 5.seconds.fromNow()
        let channel = try Channel<Void>()

        let coroutine = try Coroutine {
            let host = try TCPHost(host: "127.0.0.1", port: port, deadline: deadline)
            let stream = try host.accept(deadline: deadline)

            try stream.write("ABC", deadline: deadline)
            try stream.flush(deadline: deadline)

            let readBuffer = try stream.read(into: buffer, deadline: deadline)
            XCTAssertEqual(readBuffer.count, 9)
            XCTAssertEqual(String(data: Data(readBuffer), encoding: .utf8), "123456789")

            try channel.send(deadline: .never)
        }

        let stream = try TCPStream(host: "127.0.0.1", port: port, deadline: deadline)
        try stream.open(deadline: deadline)

        let readBuffer = try stream.read(into: buffer, deadline: deadline)
        XCTAssertEqual(String(data: Data(readBuffer), encoding: .utf8), "ABC")
        XCTAssertEqual(readBuffer.count, 3)

        try stream.write("123456789", deadline: deadline)
        try stream.flush(deadline: deadline)

        try channel.receive(deadline: .never)
        try coroutine.cancel()
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
