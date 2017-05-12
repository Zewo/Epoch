import XCTest
@testable import Venice

struct Fou {
    let bar: Int
    let baz: Int
}

public class ChannelTests : XCTestCase {
    func testChannelResultSuccess() {
        let result = ChannelResult<Int>.value(42)

        XCTAssert(result.succeeded)
        XCTAssertFalse(result.failed)

        var value = 0

        result.success { v in
            value = v
        }

        result.failure { _ in
            value = 0
        }

        XCTAssertEqual(value, 42)
    }

    func testChannelResultFailure() {
        let result = ChannelResult<Int>.error(VeniceError.unexpected)

        XCTAssert(result.failed)
        XCTAssertFalse(result.succeeded)

        var error: Error?

        result.failure { e in
            error = e
        }

        result.success { v in
            error = nil
        }

        XCTAssertEqual(error as? VeniceError, .unexpected)
    }

    func testCreationOnClosedCoroutine() throws {
        let c = try coroutine {
            try yield()

            do {
                _ = try Channel<Void>()
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .canceled)
            }
        }

        try c.close()
    }

    func testDoneOnClosedChannel() throws {
        let channel = try Channel<Void>()
        try channel.close()

        do {
            try channel.done()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .invalidHandle)
        }
    }

    func testDoneOnDoneChannel() throws {
        let channel = try Channel<Void>()
        try channel.done()

        do {
            try channel.done()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .channelIsDone)
        }
    }

    func testSendOnClosedChannel() throws {
        let channel = try Channel<Void>()
        try channel.close()

        do {
            try channel.send(())
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .invalidHandle)
        }
    }

    func testSendOnClosedCoroutine() throws {
        let channel = try Channel<Void>()

        let c = try coroutine {
            try yield()

            do {
                try channel.send(())
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .canceled)
            }
        }

        try c.close()
    }

    func testSendOnDoneChannel() throws {
        let channel = try Channel<Void>()
        try channel.done()

        do {
            try channel.send(())
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .channelIsDone)
        }
    }

    func testSendTimeout() throws {
        let channel = try Channel<Void>()

        do {
            try channel.send((), deadline: .immediately)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .timeout)
        }
    }

    func testReceiveOnClosedChannel() throws {
        let channel = try Channel<Void>()
        try channel.close()

        do {
            try channel.receive()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .invalidHandle)
        }
    }

    func testReceiveOnClosedCoroutine() throws {
        let channel = try Channel<Void>()

        let c = try coroutine {
            try yield()

            do {
                try channel.receive()
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .canceled)
            }
        }

        try c.close()
    }

    func testReceiveOnDoneChannel() throws {
        let channel = try Channel<Void>()
        try channel.done()

        do {
            try channel.receive()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .channelIsDone)
        }
    }

    func testReceiveTimeout() throws {
        let channel = try Channel<Void>()

        do {
            try channel.receive(deadline: .immediately)
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .timeout)
        }
    }

    func testReceiverWaitsForSender() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try yield()
            try channel.send(333)
        }

        XCTAssertEqual(try channel.receive(), 333)
        try c.close()
    }

    func testSenderWaitsForReceiver() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try channel.send(444)
        }

        XCTAssertEqual(try channel.receive(), 444)
        try c.close()
    }

    func testSendingChannel() throws {
        let channel = try Channel<Int>()

        func send(_ channel: SendingChannel<Int>) throws {
            try channel.send(888)
            try channel.send(VeniceError.outOfMemory)
        }

        let c = try coroutine {
            try send(channel.sending)
        }

        XCTAssertEqual(try channel.receive(), 888)

        do {
            try channel.receive()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .outOfMemory)
        }

        try c.close()
    }

    func testReceivingChannel() throws {
        let channel = try Channel<Int>()

        func receive(_ channel: ReceivingChannel<Int>) {
            XCTAssertEqual(try channel.receive(), 999)
        }

        let c = try coroutine {
            try channel.send(999)
        }

        receive(channel.receiving)
        try c.close()
    }

    func testTwoSimultaneousSenders() throws {
        let channel = try Channel<Int>()

        let c1 = try coroutine {
            try channel.send(888)
        }

        let c2 = try coroutine {
            try channel.send(999)
        }

        XCTAssertEqual(try channel.receive(), 888)
        XCTAssertEqual(try channel.receive(), 999)

        try c1.close()
        try c2.close()
    }

    func testTwoSimultaneousReceivers() throws {
        let channel = try Channel<Int>()

        let c1 = try coroutine {
            XCTAssertEqual(try channel.receive(), 333)
        }

        let c2 = try coroutine {
            XCTAssertEqual(try channel.receive(), 444)
        }

        try channel.send(333)
        try channel.send(444)

        try c1.close()
        try c2.close()
    }

    func testTypedChannels() throws {
        let stringChannel = try Channel<String>()

        let c1 = try coroutine {
            try stringChannel.send("yo")
        }

        XCTAssertEqual(try stringChannel.receive(), "yo")

        let fooChannel = try Channel<Fou>()

        let c2 = try coroutine {
            try fooChannel.send(Fou(bar: 555, baz: 222))
        }

        let foo = try fooChannel.receive()
        XCTAssertEqual(foo.bar, 555)
        XCTAssertEqual(foo.baz, 222)

        try c1.close()
        try c2.close()
    }

    func testSimpleChannelClose() throws {
        let channel = try Channel<Int>()
        try channel.done()

        do {
            try channel.receive()
            XCTFail()
        } catch {
            XCTAssertEqual(error as? VeniceError, .channelIsDone)
        }
    }

    func testChannelCloseUnblocks() throws {
        let channel1 = try Channel<Int>()
        let channel2 = try Channel<Int>()

        let c1 = try coroutine {
            do {
                try channel1.receive()
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .channelIsDone)
            }

            try channel2.send(0)
        }

        let c2 = try coroutine {
            do {
                try channel1.receive()
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .channelIsDone)
            }

            try channel2.send(0)
        }

        try channel1.done()

        XCTAssertEqual(try channel2.receive(), 0)
        XCTAssertEqual(try channel2.receive(), 0)

        try c1.close()
        try c2.close()
    }

    func testChannelIteration() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try channel.send(555)
            try channel.send(555)
            try channel.done()
        }

        for result in channel {
            XCTAssert(result.succeeded)

            result.success { value in
                XCTAssertEqual(value, 555)
            }
        }

        try c.close()
    }

    func testReceivingChannelIteration() throws {
        let channel =  try Channel<Int>()

        let c = try coroutine {
            try channel.send(444)
            try channel.send(444)
        }

        func receive(_ channel: ReceivingChannel<Int>) throws {
            for (index, result) in channel.enumerated() {
                if index == 1 {
                    try channel.done()
                }

                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssertEqual(value, 444)
                }
            }
        }

        try receive(channel.receiving)
        try c.close()
    }
}

extension ChannelTests {
    public static var allTests: [(String, (ChannelTests) -> () throws -> Void)] {
        return [
            ("testReceiverWaitsForSender", testReceiverWaitsForSender),
//            ("testSenderWaitsForReceiver", testSenderWaitsForReceiver),
//            ("testSendingChannel", testSendingChannel),
//            ("testReceivingChannel", testReceivingChannel),
//            ("testTwoSimultaneousSenders", testTwoSimultaneousSenders),
//            ("testTwoSimultaneousReceivers", testTwoSimultaneousReceivers),
//            ("testTypedChannels", testTypedChannels),
//            ("testMessageBuffering", testMessageBuffering),
//            ("testSimpleChannelClose", testSimpleChannelClose),
//            ("testChannelCloseUnblocks", testChannelCloseUnblocks),
//            ("testBlockedSenderAndItemInTheChannel", testBlockedSenderAndItemInTheChannel),
//            ("testChannelIteration", testChannelIteration),
//            ("testReceivingChannelIteration", testReceivingChannelIteration),
        ]
    }
}
