#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import Venice

public class CoroutineTests : XCTestCase {
    func testCoroutine() throws {
        var sum: Int = 0

        func worker(count: Int, n: Int) throws {
            for _ in 0 ..< count {
                sum += n
                try yield()
            }
        }

        let c1 = try coroutine {
            try worker(count: 3, n: 7)
        }

        let c2 = try coroutine {
            try worker(count: 1, n: 11)
        }

        let c3 = try coroutine {
            try worker(count: 2, n: 5)
        }

        try nap(for: 100.milliseconds)
        XCTAssert(sum == 42)

        try c1.close()
        try c2.close()
        try c3.close()
    }

    func testWakeUp() throws {
        let deadline = 100.milliseconds.fromNow()
        try wakeUp(deadline)
        let diff = now() - deadline
        XCTAssert(diff > -200.milliseconds && diff < 200.milliseconds)
    }

    func testNap() throws {
        let channel = try Channel<Duration>()

        func delay(duration: Duration) throws {
            try nap(for: duration)
            try channel.send(duration)
        }

        let c1 = try coroutine({ try delay(duration: 30.milliseconds) })
        let c2 = try coroutine({ try delay(duration: 40.milliseconds) })
        let c3 = try coroutine({ try delay(duration: 10.milliseconds) })
        let c4 = try coroutine({ try delay(duration: 20.milliseconds) })

        XCTAssert(try channel.receive() == 10.milliseconds)
        XCTAssert(try channel.receive() == 20.milliseconds)
        XCTAssert(try channel.receive() == 30.milliseconds)
        XCTAssert(try channel.receive() == 40.milliseconds)

        try c1.close()
        try c2.close()
        try c3.close()
        try c4.close()
    }

    func testPollFileDescriptor() throws {
        var fds = [Int32](repeating: 0, count: 2)

        #if os(Linux)
            let result = socketpair(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0, &fds)
        #else
            let result = socketpair(AF_UNIX, SOCK_STREAM, 0, &fds)
        #endif

        XCTAssert(result == 0)

        try poll(fds[0], event: .write, deadline: 100.milliseconds.fromNow())
        try poll(fds[0], event: .write, deadline: 100.milliseconds.fromNow())

        var e: Error?

        do {
            try poll(fds[0], event: .read, deadline: 100.milliseconds.fromNow())
            XCTFail()
        } catch {
            e = error
        }

        XCTAssertEqual(e as? VeniceError, .timeout)

        var size = send(fds[1], "A", 1, 0)
        XCTAssert(size == 1)

        try poll(fds[0], event: .write, deadline: 100.milliseconds.fromNow())
        try poll(fds[0], event: .read, deadline: 100.milliseconds.fromNow())

        var c: Int8 = 0
        size = recv(fds[0], &c, 1, 0)

        XCTAssert(size == 1)
        XCTAssert(c == 65)
    }

    func testThousandWhispers() throws {
        self.measure {
            do {
                func whisper(left: SendingChannel<Int>, right: ReceivingChannel<Int>) throws {
                    try left.send(1 + right.receive())
                }

                let numberOfWhispers = 10000

                let leftmost = try Channel<Int>()
                var right = leftmost
                var left = leftmost

                let whispers: [Handle] = try CountableRange(0 ..< numberOfWhispers).map { _ in
                    right = try Channel<Int>()

                    let c1 = try coroutine {
                        try whisper(left: left.sending, right: right.receiving)
                    }

                    left = right
                    return c1
                }

                let starter = try coroutine {
                    try right.send(1)
                }

                XCTAssert(try leftmost.receive() == numberOfWhispers + 1)

                try starter.close()
                try whispers.forEach({ try $0.close() })
            } catch {
                XCTFail()
            }
        }
    }
}

extension CoroutineTests {
    public static var allTests: [(String, (CoroutineTests) -> () throws -> Void)] {
        return [
            ("testCoroutine", testCoroutine),
            ("testWakeUp", testWakeUp),
            ("testNap", testNap),
            ("testPollFileDescriptor", testPollFileDescriptor),
            ("testThousandWhispers", testThousandWhispers),
        ]
    }
}
