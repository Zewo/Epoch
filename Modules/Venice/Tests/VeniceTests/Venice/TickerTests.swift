import XCTest
@testable import Venice

public class TickerTests : XCTestCase {
    func testTicker() {
        let tickerPeriod = 50.milliseconds
        let ticker = Ticker(period: tickerPeriod)
        co {
            var last: Double = ticker.channel.receive()!
            for time in ticker.channel {
                XCTAssertEqualWithAccuracy(time - last, tickerPeriod, accuracy: 1)
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
