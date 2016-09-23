import XCTest
import Foundation
@testable import POSIX

public class ThreadTests: XCTestCase {
    func testExecution() throws {
        let arr = [1,2,3,4,5]
        var sum: Int?

        _ = try PThread {
            sum = arr.reduce(0, +)
        }

        sleep(1)

        XCTAssertEqual(sum, 15)
    }

    func testDone() throws {
        let arr = [1,2,3,4,5]
        var sum: Int?

        let thread = try PThread {
            sum = arr.reduce(0, +)
        }

        //TODO: set a timeout that cancels the thread (we want
        // the test to fail, after all)
        while !thread.done {
            // 10ms
            usleep(10_000)
        }

        XCTAssertEqual(sum, 15)
    }

    func testJoin() throws {
        let arr = [1,2,3,4,5]

        let sum = try PThread {
            return arr.reduce(0, +)
        }.wait()

        XCTAssertEqual(sum, 15)
    }

    struct TestError: Error {}
    func testCatchesErrors() {
        let result = try? PThread<Int> {
            throw TestError()
        }.wait()

        XCTAssertNil(result)
    }

    // A reminder of the inherent unsafety of using c
    // apis (crashes due to type mismatch)
    //func testGracefullyExits() throws {
    //    _ = try Thread<String> {
    //        var value = 10
    //        pthread_exit(&value)
    //    }.join()
    //}
}

extension ThreadTests {
    public static var allTests : [(String, (ThreadTests) -> () throws -> Void)] {
        return [
            ("testExecution", testExecution),
            ("testDone", testDone),
            ("testJoin", testJoin),
            ("testCatchesErrors", testCatchesErrors)
        ]
    }
}
