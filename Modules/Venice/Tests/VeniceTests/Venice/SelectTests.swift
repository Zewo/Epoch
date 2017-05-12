import XCTest
@testable import Venice

public class SelectTests : XCTestCase {
    func testNonBlockingReceiver() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try channel.send(555)
        }

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssertEqual(value, 555)
                }
            }
        }

        try c.close()
    }

    func testBlockingReceiver() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try yield()
            try channel.send(666)
        }

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssertEqual(value, 666)
                }
            }
        }

        try c.close()
    }

    func testNonBlockingSender() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            XCTAssertEqual(try channel.receive(), 777)
        }

        var called = false

        try select { when in
            when.send(777, to: channel) { result in
                XCTAssert(result.succeeded)
                called = true
            }
        }

        XCTAssert(called)

        try c.close()
    }

    func testBlockingSender() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try yield()
            XCTAssertEqual(try channel.receive(), 888)
        }

        var called = false

        try select { when in
            when.send(888, to: channel) { result in
                XCTAssert(result.succeeded)
                called = true
            }
        }

        XCTAssert(called)

        try c.close()
    }

    func testTwoChannels() throws {
        let channel1 = try Channel<Int>()
        let channel2 = try Channel<Int>()

        let c1 = try coroutine {
            try channel1.send(555)
        }

        try select { when in
            when.receive(from: channel1) { result in
                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssertEqual(value, 555)
                }
            }

            when.receive(from: channel2) { _ in
                XCTFail()
            }
        }

        let c2 = try coroutine {
            try yield()
            try channel2.send(666)
        }

        try select { when in
            when.receive(from: channel1) { _ in
                XCTFail()
            }

            when.receive(from: channel2) { result in
                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssertEqual(value, 666)
                }
            }
        }

        try c1.close()
        try c2.close()
    }

    func testTimeoutImediately() throws {
        let channel = try Channel<Int>()
        var called = false

        try select { when in
            when.receive(from: channel) { _ in
                XCTFail()
            }

            when.timeout(deadline: .immediately) {
                called = true
            }
        }

        XCTAssert(called)
        called = false

        try select { when in
            when.timeout(deadline: .immediately) {
                called = true
            }
        }

        XCTAssert(called)
    }

    func testTwoSimultaneousSenders() throws {
        let channel = try Channel<Int>()

        let c1 = try coroutine {
            try channel.send(888)
        }

        let c2 =  try coroutine {
            try channel.send(999)
        }

        var value = 0

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.succeeded)

                result.success { v in
                    value = v
                }
            }
        }

        XCTAssertEqual(value, 888)
        value = 0

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.succeeded)

                result.success { v in
                    value = v
                }
            }
        }

        XCTAssertEqual(value, 999)
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

        var called = false

        try select { when in
            when.send(333, to: channel) { _ in
                called = true
            }
        }

        XCTAssert(called)
        called = false

        try select { when in
            when.send(444, to: channel) { _ in
                called = true
            }
        }

        XCTAssert(called)
        try c1.close()
        try c2.close()
    }

    func testSelectWithSelect() throws {
        let channel = try Channel<Int>()
        var called = false

        let c = try coroutine {
            try select { when in
                when.send(111, to: channel) { result in
                    XCTAssert(result.succeeded)
                    called = true
                }
            }
        }

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssertEqual(value, 111)
                }
            }
        }

        try yield()
        XCTAssert(called)
        try c.close()
    }

    func testReceiveSelectFromDoneChannel() throws {
        let channel = try Channel<Int>()

        try channel.done()

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.failed)

                result.failure { error in
                    XCTAssertEqual(error as? VeniceError, .channelIsDone)
                }
            }
        }
    }

    func testReceivingFromReceivingChannel() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try channel.send(555)
        }

        var value = 0

        try select { when in
            when.receive(from: channel.receiving) { result in
                XCTAssert(result.succeeded)

                result.success { v in
                    value = v
                }
            }
        }

        XCTAssert(value == 555)
        try c.close()
    }

    func testReceivingErrorFromChannel() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try channel.send(VeniceError.unexpected)
        }

        var error: Error?

        try select { when in
            when.receive(from: channel) { result in
                XCTAssert(result.failed)

                result.failure { e in
                    error = e
                }
            }
        }

        XCTAssertEqual(error as? VeniceError, .unexpected)
        try c.close()
    }

    func testReceivingErrorFromReceivingChannel() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            try channel.send(VeniceError.unexpected)
        }

        var error: Error?

        try select { when in
            when.receive(from: channel.receiving) { result in
                XCTAssert(result.failed)

                result.failure { e in
                    error = e
                }
            }
        }

        XCTAssertEqual(error as? VeniceError, .unexpected)
        try c.close()
    }

    func testSendingToSendingChannel() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            XCTAssertEqual(try channel.receive(), 777)
        }

        var called = false

        try select { when in
            when.send(777, to: channel.sending) { result in
                XCTAssert(result.succeeded)
                called = true
            }
        }

        XCTAssert(called)
        try c.close()
    }

    func testSendingErrorToChannel() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            do {
                try channel.receive()
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .unexpected)
            }
        }

        var called = false

        try select { when in
            when.send(VeniceError.unexpected, to: channel) { result in
                XCTAssert(result.succeeded)
                called = true
            }
        }

        XCTAssert(called)
        try c.close()
    }


    func testSendingErrorToSendingChannel() throws {
        let channel = try Channel<Int>()

        let c = try coroutine {
            do {
                try channel.receive()
                XCTFail()
            } catch {
                XCTAssertEqual(error as? VeniceError, .unexpected)
            }
        }

        var called = false

        try select { when in
            when.send(VeniceError.unexpected, to: channel.sending) { result in
                XCTAssert(result.succeeded)
                called = true
            }
        }

        XCTAssert(called)
        try c.close()
    }

    func testTimeout() throws {
        var called = false

        try select { when in
            when.timeout(deadline: 10.milliseconds.fromNow()) {
                called = true
            }
        }

        XCTAssert(called)
    }

    func testForSelect() throws {
        let channel = try Channel<Int>()

        let c1 = try after(10.milliseconds) { _ in
            try channel.send(444)
        }

        let c2 = try after(20.milliseconds) { _ in
            try channel.send(444)
        }
        
        var count = 0

        try forSelect { when, done in
            when.receive(from: channel) { result in
                XCTAssert(result.succeeded)

                result.success { value in
                    XCTAssert(value == 444)
                }

                count += 1

                if count == 2 {
                    done()
                }
            }
        }

        try c1.close()
        try c2.close()
    }
}

extension SelectTests {
    func assert<T, E>(channel: Channel<T>, catchesErrorOfType type: E.Type) {
        var thrown = false
        do {
            try channel.receive()
        } catch _ as E {
            thrown = true
        } catch {}
        XCTAssert(thrown)
    }

    func assert<T, E>(channel: ReceivingChannel<T>, catchesErrorOfType type: E.Type) {
        var thrown = false
        do {
            try channel.receive()
        } catch _ as E {
            thrown = true
        } catch {}
        XCTAssert(thrown)
    }
}

extension SelectTests {
    public static var allTests: [(String, (SelectTests) -> () throws -> Void)] {
        return [
            ("testNonBlockingReceiver", testNonBlockingReceiver),
//            ("testBlockingReceiver", testBlockingReceiver),
//            ("testNonBlockingSender", testNonBlockingSender),
//            ("testBlockingSender", testBlockingSender),
//            ("testTwoChannels", testTwoChannels),
//            ("testReceiveRandomChannelSelection", testReceiveRandomChannelSelection),
//            ("testSendRandomChannelSelection", testSendRandomChannelSelection),
//            ("testOtherwise", testOtherwise),
//            ("testTwoSimultaneousSenders", testTwoSimultaneousSenders),
//            ("testTwoSimultaneousReceivers", testTwoSimultaneousReceivers),
//            ("testSelectWithSelect", testSelectWithSelect),
//            ("testSelectWithBufferedChannels", testSelectWithBufferedChannels),
//            ("testReceiveSelectFromClosedChannel", testReceiveSelectFromClosedChannel),
//            ("testRandomReceiveSelectionWhenNothingImmediatelyAvailable", testRandomReceiveSelectionWhenNothingImmediatelyAvailable),
//            ("testRandomSendSelectionWhenNothingImmediatelyAvailable", testRandomSendSelectionWhenNothingImmediatelyAvailable),
//            ("testReceivingFromSendingChannel", testReceivingFromSendingChannel),
//            ("testReceivingFromFallibleChannel", testReceivingFromFallibleChannel),
//            ("testReceivingErrorFromFallibleChannel", testReceivingErrorFromFallibleChannel),
//            ("testReceivingFromFallibleSendingChannel", testReceivingFromFallibleSendingChannel),
//            ("testReceivingErrorFromFallibleSendingChannel", testReceivingErrorFromFallibleSendingChannel),
//            ("testSendingToReceivingChannel", testSendingToReceivingChannel),
//            ("testSendingToFallibleChannel", testSendingToFallibleChannel),
//            ("testThrowingErrorIntoFallibleChannel", testThrowingErrorIntoFallibleChannel),
//            ("testSendingToFallibleReceivingChannel", testSendingToFallibleReceivingChannel),
//            ("testThrowingErrorIntoFallibleReceivingChannel", testThrowingErrorIntoFallibleReceivingChannel),
//            ("testTimeout", testTimeout),
//            ("testForSelect", testForSelect),
        ]
    }
}
