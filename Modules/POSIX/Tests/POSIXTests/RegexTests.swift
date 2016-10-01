import XCTest
@testable import POSIX

public class RegexTests: XCTestCase {

    func testInvalidRegex() {
        XCTAssertThrowsError(try Regex(pattern: "("))
        XCTAssertThrowsError(try Regex(pattern: "*"))
    }

    func testMatches() throws {
        let regex = try Regex(pattern: "hello")
        let matches = regex.matches("hello")
        XCTAssert(matches)
    }

    func testNotMatches() throws {
        let regex = try Regex(pattern: "hello")
        let matches = regex.matches("bye")
        XCTAssert(!matches)
    }

    func testGroup() throws {
        let regex = try Regex(pattern: "(hello)")
        let groups = regex.groups(in: "hello")
        XCTAssert(groups == ["hello"])
    }

    func testGroups() throws {
        let regex = try Regex(pattern: "(hello) (world)")
        let groups = regex.groups(in: "hello world")
        XCTAssert(groups == ["hello", "world"])
    }

    func testNoGroups() throws {
        let regex = try Regex(pattern: "(hello)")
        let groups = regex.groups(in: "bye")
        XCTAssert(groups == [])
    }

    /// Replace one occurence by a shorter template string
    func testReplaceOneOccurenceWithShorterTemplate() throws {
        let regex = try Regex(pattern: "hello")
        let string = regex.replace(with: "bye", in: "hello world")
        XCTAssert(string == "bye world")
    }

    /// Replace one occurence by a longer template string
    func testReplaceOneOccurenceWithLongerTemplate() throws {
        let regex = try Regex(pattern: "o")
        let string = regex.replace(with: "ooo!", in: "hello")
        XCTAssertEqual(string, "hellooo!")
    }

    /// Replace multiple occurences each by a shorter template string
    func testReplaceManyOccurencesWithShorterTemplate() throws {
        let regex = try Regex(pattern: "mm")
        let string = regex.replace(with: "M", in: "mm-mm")
        XCTAssertEqual(string, "M-M")
    }

    /// Replace multiple occurences each by a longer template string
    func testReplaceManyOccurencesWithLongerTemplate() throws {
        let regex = try Regex(pattern: "l")
        let string = regex.replace(with: "LL", in: "lol")
        XCTAssertEqual(string, "LLoLL")
    }

    /// Replace each digit
    func testReplaceDigits() throws {
        let regex = try Regex(pattern: "[0-9]")
        let string = regex.replace(with: ".", in: "1234")
        XCTAssertEqual(string, "....")
    }

    /// Replace number
    func testReplaceNumber() throws {
        let regex = try Regex(pattern: "[0-9]+")
        let string = regex.replace(with: ".", in: "1234")
        XCTAssertEqual(string, ".")
    }

    func testNoReplace() throws {
        let regex = try Regex(pattern: "bye")
        let string = regex.replace(with: "bye", in: "hello world")
        XCTAssert(string == "hello world")
    }
    
    func testReplaceUTF8() throws {
        let r0 = try Regex(pattern: "coffee")
        let actual0 = r0.replace(with: "☕️", in: "Paulo loves coffee")
        let expected0 = "Paulo loves ☕️"
        XCTAssertEqual(actual0, expected0)
        
        let r1 = try Regex(pattern: "☕️")
        let actual1 = r1.replace(with: "🍻", in: actual0)
        let expected1 = "Paulo loves 🍻"
        XCTAssertEqual(actual1, expected1)
        
    }
    
    func testMultipleReplacesUTF8() throws {
        let r1 = try Regex(pattern: "[[:digit:]]{4}")
        let actual1 = r1.replace(with: "💳", in: "1234-2345-3456-4567")
        XCTAssertEqual(actual1, "💳-💳-💳-💳")
    }


    /// MARK: - matching test

    func testMatchesUsingOperators() throws {
        XCTAssert(try ("hello world" ~ "hello"))
        XCTAssert(("hello world" ~? "hello")!)

        XCTAssert(try "hello world" ~ "[[:alpha:]]")
        XCTAssert(try "hello world 1" ~ "[[:digit:]]")
        XCTAssertFalse(try "hello world" ~ "[[:digit:]]")

        // invalid Regex
        XCTAssertThrowsError(try "hello world 1" ~  "*")
        XCTAssertNil(            "hello world 1" ~? "*")

        // slightly more complex regexes
        XCTAssert(     try "111-2222-333" ~ "[[:digit:]]{3}-[[:digit:]]{4}-[[:digit:]]{3}")
        XCTAssert(     try "111-aaaa-333" ~ "[[:digit:]]{3}-[[:alpha:]]{4}-[[:digit:]]{3}")
        XCTAssertFalse(try "111-aaaa-333" ~ "[[:digit:]]{3}-[[:digit:]]{4}-[[:digit:]]{3}")

        // no throws or optionals if regex pre-exists
        let r0 = try Regex(pattern: "[[:alpha:]]")
        XCTAssert("hello world 1" ~ r0)

        let r1 = try Regex(pattern: "[[:digit:]]{3}-[[:digit:]]{4}-[[:digit:]]{3}")
        XCTAssert("111-2222-333" ~ r1)
    }

    func testGroupsUsingOperators() throws {

        // one group
        let digits = try Regex(pattern: "[[:digit:]]{3}-([[:digit:]]{4})-[[:digit:]]{3}")

        XCTAssertEqual("111-2222-333" ~* digits, ["2222"])

        let actual0 = ("111-2222-333" ~* digits).map { s in Int(s)! }
        XCTAssertEqual(actual0, [2222])

        // two groups
        let actual1 = (try "hel lo world" ~* "(hel)[[:space:]]?(lo)")
        XCTAssertEqual(actual1, ["hel", "lo"])

        // using map
        let actual2 = (try "hel lo world" ~* "(hel)[[:space:]]?(lo)").map { s in s.uppercased() }
        XCTAssertEqual(actual2, ["HEL", "LO"])

        // casting with flatMap
        let actual3 = (try "Paulo have 3 cats" ~* "([[:digit:]]+)").flatMap { (v: String) -> Int? in
            return Int(v)
        }
        XCTAssertEqual(actual3, [3])

        // matching the empty string bails out
        let actual4 = try "I have 3 cats" ~* "([[:digit:]]*)"
        XCTAssertEqual(actual4, [])

        XCTAssertEqual(try "I have 3 cats" ~* "([[:digit:]]+)", ["3"])
        XCTAssertEqual(try "Paulo has 3 cats" ~* "([[:alpha:]]+).*([[:digit:]]+)", ["Paulo", "3"])

        // using utf8
        XCTAssertEqual(try "Paulo likes ☕️" ~* "([[:alpha:]]+).*(☕️)", ["Paulo", "☕️"])


        //: using an existing Regex instance
        let r1 = try Regex(pattern: "(hel)(lo)")

        XCTAssertEqual("hello world" ~* r1, ["hel", "lo"])

        /// example with mapped
        let actual5 = ("hello world" ~* r1).map { match in return match.uppercased() }
        XCTAssertEqual(actual5, ["HEL", "LO"])

        /// example with flatMap
        let actual6 = ("hello world" ~* r1).flatMap { (v: String) -> String? in
            return v.contains("lo") ? v.uppercased() : nil
        }
        XCTAssertEqual(actual6, ["LO"])


    }

}

extension RegexTests {
    public static var allTests: [(String, (RegexTests) -> () throws -> Void)] {
        return [
           ("testInvalidRegex", testInvalidRegex),
           ("testMatches", testMatches),
           ("testNotMatches", testNotMatches),
           ("testGroup", testGroup),
           ("testGroups", testGroups),
           ("testNoGroups", testNoGroups),
           ("testReplaceOneOccurenceWithShorterTemplate",   testReplaceOneOccurenceWithShorterTemplate),
           ("testReplaceOneOccurenceWithLongerTemplate",    testReplaceOneOccurenceWithLongerTemplate),
           ("testReplaceManyOccurencesWithShorterTemplate", testReplaceManyOccurencesWithShorterTemplate),
           ("testReplaceManyOccurencesWithLongerTemplate",  testReplaceManyOccurencesWithLongerTemplate),
           ("testReplaceDigits", testReplaceDigits),
           ("testReplaceNumber", testReplaceNumber),
           ("testNoReplace", testNoReplace),
           ("testMatchesUsingOperators", testMatchesUsingOperators),
           ("testGroupsUsingOperators", testGroupsUsingOperators),
        ]
    }
}
