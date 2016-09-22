import XCTest
@testable import Venice

struct Fou {
    let bar: Int
    let baz: Int
}

public class ChannelTests : XCTestCase {
    func testReceiverWaitsForSender() {
        let channel = Channel<Int>()
        co {
            yield
            channel.send(333)
        }
        XCTAssert(channel.receive() == 333)
    }

    func testSenderWaitsForReceiver() {
        let channel = Channel<Int>()
        co {
            channel.send(444)
        }
        XCTAssert(channel.receive() == 444)
    }

    func testSendingChannel() {
        let channel = Channel<Int>()
        func send(_ channel: SendingChannel<Int>) {
            channel.send(888)
        }
        co(send(channel.sendingChannel))
        XCTAssert(channel.receive() == 888)
    }

    func testReceivingChannel() {
        let channel = Channel<Int>()
        func receive(_ channel: ReceivingChannel<Int>) {
            XCTAssert(channel.receive() == 999)
        }
        co {
            channel.send(999)
        }
        receive(channel.receivingChannel)
    }

    func testTwoSimultaneousSenders() {
        let channel = Channel<Int>()
        co {
            channel.send(888)
        }
        co {
            channel.send(999)
        }
        XCTAssert(channel.receive() == 888)
        yield
        XCTAssert(channel.receive() == 999)
    }

    func testTwoSimultaneousReceivers() {
        let channel = Channel<Int>()
        co {
            XCTAssert(channel.receive() == 333)
        }
        co {
            XCTAssert(channel.receive() == 444)
        }
        channel.send(333)
        channel.send(444)
    }

    func testTypedChannels() {
        let stringChannel = Channel<String>()
        co {
            stringChannel.send("yo")
        }
        XCTAssert(stringChannel.receive() == "yo")

        let fooChannel = Channel<Fou>()
        co {
            fooChannel.send(Fou(bar: 555, baz: 222))
        }
        let foo = fooChannel.receive()
        XCTAssert(foo?.bar == 555 && foo?.baz == 222)
    }

    func testMessageBuffering() {
        let channel = Channel<Int>(bufferSize: 2)
        channel.send(222)
        channel.send(333)
        XCTAssert(channel.receive() == 222)
        XCTAssert(channel.receive() == 333)
        channel.send(444)
        XCTAssert(channel.receive() == 444)
        channel.send(555)
        channel.send(666)
        XCTAssert(channel.receive() == 555)
        XCTAssert(channel.receive() == 666)
    }

    func testSimpleChannelClose() {
        let channel1 = Channel<Int>()
        channel1.close()
        XCTAssert(channel1.receive() == nil)
        XCTAssert(channel1.receive() == nil)
        XCTAssert(channel1.receive() == nil)

        let channel2 = Channel<Int>(bufferSize: 10)
        channel2.close()
        XCTAssert(channel2.receive() == nil)
        XCTAssert(channel2.receive() == nil)
        XCTAssert(channel2.receive() == nil)

        let channel3 = Channel<Int>(bufferSize: 10)
        channel3.send(999)
        channel3.close()
        XCTAssert(channel3.receive() == 999)
        XCTAssert(channel3.receive() == nil)
        XCTAssert(channel3.receive() == nil)

        let channel4 = Channel<Int>(bufferSize: 1)
        channel4.send(222)
        channel4.close()
        XCTAssert(channel4.receive() == 222)
        XCTAssert(channel4.receive() == nil)
        XCTAssert(channel4.receive() == nil)
    }

    func testChannelCloseUnblocks() {
        let channel1 = Channel<Int>()
        let channel2 = Channel<Int>()
        co {
            co {
                XCTAssert(channel1.receive() == nil)
                channel2.send(0)
            }
            co {
                XCTAssert(channel1.receive() == nil)
                channel2.send(0)
            }
        }
        channel1.close()
        XCTAssert(channel2.receive() == 0)
        XCTAssert(channel2.receive() == 0)
    }

    func testBlockedSenderAndItemInTheChannel() {
        let channel = Channel<Int>(bufferSize: 1)
        channel.send(1)
        co {
            channel.send(2)
        }
        XCTAssert(channel.receive() == 1)
        XCTAssert(channel.receive() == 2)
    }

    func testPanicWhenSendingToChannelDeadlocks() {
        // These work on Xcode locally but not on Travis
#if Xcode
//        let pid = fork()
//        XCTAssert(pid >= 0)
//        if pid == 0 {
//            alarm(1)
//            let channel = Channel<Int>()
//            signal(SIGABRT) { _ in
//                _exit(0)
//            }
//            channel.send(42)
//            XCTFail()
//        }
//        var exitCode: Int32 = 0
//        XCTAssert(waitpid(pid, &exitCode, 0) != 0)
//        XCTAssert(exitCode == 0)
#endif
    }

    func testPanicWhenReceivingFromChannelDeadlocks() {
        // These work on Xcode locally but not on Travis
#if Xcode
//        let pid = fork()
//        XCTAssert(pid >= 0)
//        if pid == 0 {
//            alarm(1)
//            let channel = Channel<Int>()
//            signal(SIGABRT) { _ in
//                _exit(0)
//            }
//            channel.receive()
//            XCTFail()
//        }
//        var exitCode: Int32 = 0
//        XCTAssert(waitpid(pid, &exitCode, 0) != 0)
//        XCTAssert(exitCode == 0)
#endif
    }

    func testChannelIteration() {
        let channel =  Channel<Int>(bufferSize: 2)
        channel.send(555)
        channel.send(555)
        channel.close()
        for value in channel {
            XCTAssert(value == 555)
        }
    }

    func testReceivingChannelIteration() {
        let channel =  Channel<Int>(bufferSize: 2)
        channel.send(444)
        channel.send(444)
        func receive(_ channel: ReceivingChannel<Int>) {
            channel.close()
            for value in channel {
                XCTAssert(value == 444)
            }
        }
        receive(channel.receivingChannel)
    }
}

extension ChannelTests {
    public static var allTests: [(String, (ChannelTests) -> () throws -> Void)] {
        return [
            ("testReceiverWaitsForSender", testReceiverWaitsForSender),
            ("testSenderWaitsForReceiver", testSenderWaitsForReceiver),
            ("testSendingChannel", testSendingChannel),
            ("testReceivingChannel", testReceivingChannel),
            ("testTwoSimultaneousSenders", testTwoSimultaneousSenders),
            ("testTwoSimultaneousReceivers", testTwoSimultaneousReceivers),
            ("testTypedChannels", testTypedChannels),
            ("testMessageBuffering", testMessageBuffering),
            ("testSimpleChannelClose", testSimpleChannelClose),
            ("testChannelCloseUnblocks", testChannelCloseUnblocks),
            ("testBlockedSenderAndItemInTheChannel", testBlockedSenderAndItemInTheChannel),
            ("testPanicWhenSendingToChannelDeadlocks", testPanicWhenSendingToChannelDeadlocks),
            ("testPanicWhenReceivingFromChannelDeadlocks", testPanicWhenReceivingFromChannelDeadlocks),
            ("testChannelIteration", testChannelIteration),
            ("testReceivingChannelIteration", testReceivingChannelIteration),
        ]
    }
}
