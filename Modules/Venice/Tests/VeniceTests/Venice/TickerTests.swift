import XCTest
@testable import Venice

public class TickerTests : XCTestCase {
    func testTicker() {
        let tickerPeriod = 50.milliseconds
        let ticker = Ticker(period: tickerPeriod)
        co {
            var last = ticker.channel.receive()!
            for time in ticker.channel {
                XCTAssertEqualWithAccuracy(time - last, tickerPeriod, accuracy: tickerPeriod)
                last = time
            }
        }
        nap(for: 300.milliseconds)
        ticker.stop()
        nap(for: 20.milliseconds)
    }
}

extension TickerTests {
    public static var allTests: [(String, (TickerTests) -> () throws -> Void)] {
        return [
            ("testTicker", testTicker),
        ]
    }
}
