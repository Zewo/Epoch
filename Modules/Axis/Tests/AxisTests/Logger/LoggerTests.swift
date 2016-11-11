import XCTest
import Foundation
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

    func testDateFormatter() throws {
        let formatter = Logger.logTimeFormatter
        formatter.timeZone = TimeZone(identifier: "GMT")
        let usLocale = Locale(identifier: "en_US")

        func testLocale(_ locale: Locale, with timestamps: [Double:String]) {
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyMMdd HHmmssSSS", options: 0, locale: locale)
            for (timestamp, expected) in timestamps {
                let date = Date(timeIntervalSince1970: timestamp)
                let formatted = formatter.string(from: date)
                XCTAssertEqual(formatted, expected)
            }
        }

        testLocale(usLocale, with: [
            -31536000  : "01/01/69, 00:00:00.000", 0          : "01/01/70, 00:00:00.000",
            31536000   : "01/01/71, 00:00:00.000", 2145916800 : "01/01/38, 00:00:00.000",
            1456272000 : "02/24/16, 00:00:00.000", 1456358399 : "02/24/16, 23:59:59.000",
            1452574638 : "01/12/16, 04:57:18.000", 1455728238 : "02/17/16, 16:57:18.000",
            1458622638 : "03/22/16, 04:57:18.000", 1459789038 : "04/04/16, 16:57:18.000",
            1462597038 : "05/07/16, 04:57:18.000", 1465577838 : "06/10/16, 16:57:18.000",
            1469854638 : "07/30/16, 04:57:18.000", 1470761838 : "08/09/16, 16:57:18.000",
            1473915438 : "09/15/16, 04:57:18.000", 1477328238 : "10/24/16, 16:57:18.000",
            1478062638 : "11/02/16, 04:57:18.000", 1482685038 : "12/25/16, 16:57:18.000"
        ])
    }
}

extension LoggerTests {
    public static var allTests: [(String, (LoggerTests) -> () throws -> Void)] {
        return [
            ("testLogger", testLogger),
            ("testDateFormatter", testDateFormatter)
        ]
    }
}
