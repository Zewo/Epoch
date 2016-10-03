import XCTest
@testable import Axis

public class LoggerTests : XCTestCase {
    func testLogger() throws {
        let appender = StandardOutputAppender()
        let logger = Logger(appenders: [appender])
        logger.trace("foo")
        XCTAssertTrue(appender.lastMessage.has(suffix: "foo"))
        logger.debug("bar")
        XCTAssertTrue(appender.lastMessage.has(suffix: "bar"))
        logger.info("foo")
        XCTAssertTrue(appender.lastMessage.has(suffix: "foo"))
        logger.warning("bar")
        XCTAssertTrue(appender.lastMessage.has(suffix: "bar"))
        logger.error("foo")
        XCTAssertTrue(appender.lastMessage.has(suffix: "foo"))
        logger.fatal("bar")
        XCTAssertTrue(appender.lastMessage.has(suffix: "bar"))
        appender.levels = [.warning]
        logger.error("foo")
        XCTAssertEqual(appender.lastMessage, "")
        struct LoggerError : Error, CustomStringConvertible {
            let description: String
        }
        logger.warning("foo", error: LoggerError(description: "bar"))
        XCTAssertTrue(appender.lastMessage.contains(substring: "foo:bar"))
    }
}

extension LoggerTests {
    public static var allTests: [(String, (LoggerTests) -> () throws -> Void)] {
        return [
            ("testLogger", testLogger),
        ]
    }
}
