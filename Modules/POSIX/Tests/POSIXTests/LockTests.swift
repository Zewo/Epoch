import XCTest
import Foundation
@testable import POSIX

public class LockTests: XCTestCase {
    func testWaitsForCondition() throws {
        let start = NSDate().timeIntervalSince1970

        let condition = try Condition()
        let lock = try Lock()

        _ = try PThread {
            sleep(1)
            condition.resolve()
        }

        try lock.withLock {
            lock.wait(for: condition)
        }

        let duration = NSDate().timeIntervalSince1970 - start
        XCTAssertGreaterThan(duration, 1)
    }

    func testLockEnsuresThreadSafety() throws {
        // if it doesnt crash, it succeeds

        let lock = try Lock()
        var results = [Int]()

        _ = try PThread {
            for i in 1...10000 {
                try lock.withLock {
                    results.append(i)
                }
            }
        }
        _ = try PThread {
            for i in 1...10000 {
                try lock.withLock {
                    results.append(i)
                }
            }
        }

        sleep(1)
    }
}

extension LockTests {
    public static var allTests : [(String, (LockTests) -> () throws -> Void)] {
        return [
           ("testWaitsForCondition", testWaitsForCondition),
           ("testLockEnsuresThreadSafety", testLockEnsuresThreadSafety)
        ]
    }
}
