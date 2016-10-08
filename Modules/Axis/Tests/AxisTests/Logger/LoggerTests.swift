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

  func testDateFormatter() throws {
    let logTimeFormatter = Logger.logTimeFormatter;
    logTimeFormatter.timeZone = TimeZone(identifier: "GMT")
    let usLocale = Locale(identifier: "en_US")
    logTimeFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyMMdd HHmmssSSS z", options: 0, locale: usLocale);
    let usTimestamps = [
      -31536000 : "01/01/69, 00:00:00.000 GMT" , 0.0 : "01/01/70, 00:00:00.000 GMT",
      31536000 : "01/01/71, 00:00:00.000 GMT", 2145916800 : "01/01/38, 00:00:00.000 GMT",
      1456272000 : "02/24/16, 00:00:00.000 GMT", 1456358399 : "02/24/16, 23:59:59.000 GMT",
      1452574638 : "01/12/16, 04:57:18.000 GMT", 1455728238 : "02/17/16, 16:57:18.000 GMT",
      1458622638 : "03/22/16, 04:57:18.000 GMT", 1459789038 : "04/04/16, 16:57:18.000 GMT",
      1462597038 : "05/07/16, 04:57:18.000 GMT", 1465577838 : "06/10/16, 16:57:18.000 GMT",
      1469854638 : "07/30/16, 04:57:18.000 GMT", 1470761838 : "08/09/16, 16:57:18.000 GMT",
      1473915438 : "09/15/16, 04:57:18.000 GMT", 1477328238 : "10/24/16, 16:57:18.000 GMT",
      1478062638 : "11/02/16, 04:57:18.000 GMT", 1482685038 : "12/25/16, 16:57:18.000 GMT"
    ]

    for (timestamp, stringResult) in usTimestamps {
      let testDate = Date(timeIntervalSince1970: timestamp)
      let sf = logTimeFormatter.string(from: testDate)
      XCTAssertEqual(sf, stringResult)
    }

    let itLocale = Locale(identifier: "it_IT");
    logTimeFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyMMdd HHmmssSSS z", options: 0, locale: itLocale);
    let itTimestamps = [
      -31536000 : "01/01/69, 00:00:00,000 GMT" , 0.0 : "01/01/70, 00:00:00,000 GMT",
      31536000 : "01/01/71, 00:00:00,000 GMT", 2145916800 : "01/01/38, 00:00:00,000 GMT",
      1456272000 : "24/02/16, 00:00:00,000 GMT", 1456358399 : "24/02/16, 23:59:59,000 GMT",
      1452574638 : "12/01/16, 04:57:18,000 GMT", 1455728238 : "17/02/16, 16:57:18,000 GMT",
      1458622638 : "22/03/16, 04:57:18,000 GMT", 1459789038 : "04/04/16, 16:57:18,000 GMT",
      1462597038 : "07/05/16, 04:57:18,000 GMT", 1465577838 : "10/06/16, 16:57:18,000 GMT",
      1469854638 : "30/07/16, 04:57:18,000 GMT", 1470761838 : "09/08/16, 16:57:18,000 GMT",
      1473915438 : "15/09/16, 04:57:18,000 GMT", 1477328238 : "24/10/16, 16:57:18,000 GMT",
      1478062638 : "02/11/16, 04:57:18,000 GMT", 1482685038 : "25/12/16, 16:57:18,000 GMT"
    ]

    for (timestamp, stringResult) in itTimestamps {
      let testDate = Date(timeIntervalSince1970: timestamp)
      let sf = logTimeFormatter.string(from: testDate)
      XCTAssertEqual(sf, stringResult)
    }
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
