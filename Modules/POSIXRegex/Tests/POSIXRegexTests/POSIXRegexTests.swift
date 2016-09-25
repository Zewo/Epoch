import XCTest
@testable import POSIXRegex

class POSIXRegexTests: XCTestCase {
    func testInvalidRegex() {
        var called = false
        do {
            let _ = try Regex(pattern: "(")
            XCTAssert(false)
        } catch {
            called = true
        }
        XCTAssert(called)
    }

    func testMatches() {
        let regex = try! Regex(pattern: "hello")
        let matches = regex.matches("hello")
        XCTAssert(matches)
    }

    func testNotMatches() {
        let regex = try! Regex(pattern: "hello")
        let matches = regex.matches("bye")
        XCTAssert(!matches)
    }

    func testGroup() {
        let regex = try! Regex(pattern: "(hello)")
        let groups = regex.groups("hello")
        XCTAssert(groups == ["hello"])
    }

    func testGroups() {
        let regex = try! Regex(pattern: "(hello) (world)")
        let groups = regex.groups("hello world")
        XCTAssert(groups == ["hello", "world"])
    }

    func testNoGroups() {
        let regex = try! Regex(pattern: "(hello)")
        let groups = regex.groups("bye")
        XCTAssert(groups == [])
    }

    func testReplace() {
        let regex = try! Regex(pattern: "hello")
        let string = regex.replace("hello world", withTemplate: "bye")
        XCTAssert(string == "bye world")
    }

    func testNoReplace() {
        let regex = try! Regex(pattern: "bye")
        let string = regex.replace("hello world", withTemplate: "bye")
        XCTAssert(string == "hello world")
    }
}

extension POSIXRegexTests {
    static var allTests: [(String, (POSIXRegexTests) -> () throws -> Void)] {
        return [
           ("testInvalidRegex", testInvalidRegex),
           ("testMatches", testMatches),
           ("testNotMatches", testNotMatches),
           ("testGroup", testGroup),
           ("testGroups", testGroups),
           ("testNoGroups", testNoGroups),
           ("testReplace", testReplace),
           ("testNoReplace", testNoReplace),
        ]
    }
}
