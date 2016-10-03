import XCTest
@testable import Core

public class StringTests : XCTestCase {
    func testCString() {
        let validUTF8: [CChar] = [67, 97, 102, -61, -87, 0]
        validUTF8.withUnsafeBufferPointer { ptr in
            XCTAssertEqual(String(cString: ptr.baseAddress!, length: validUTF8.count), "Café")
        }

        let invalidUTF8: [CChar] = [67, 97, 102, -61, 0]
        invalidUTF8.withUnsafeBufferPointer { ptr in
            XCTAssertEqual(String(cString: ptr.baseAddress!, length: invalidUTF8.count), "Caf�")
        }
    }

    func testCapitalization() {
        XCTAssertEqual("foo".capitalizedWord(), "Foo")
        XCTAssertEqual("fOo".capitalizedWord(), "Foo")
        XCTAssertEqual("fOO".capitalizedWord(), "Foo")
        XCTAssertEqual("Foo".capitalizedWord(), "Foo")
        XCTAssertEqual("FOO".capitalizedWord(), "Foo")
    }

    func testSplit() {
        XCTAssertEqual("".split(separator: " "), [])
        XCTAssertEqual("foo".split(separator: " "), ["foo"])
        XCTAssertEqual("".split(separator: " ", omittingEmptySubsequences: true), [])
        XCTAssertEqual("foo".split(separator: " ", omittingEmptySubsequences: true), ["foo"])
        XCTAssertEqual("foo bar baz".split(separator: " "), ["foo", "bar", "baz"])
        XCTAssertEqual("foo bar baz".split(separator: " ", maxSplits: 1), ["foo", "bar baz"])
        XCTAssertEqual("foo  bar baz".split(separator: " ", maxSplits: 1), ["foo", " bar baz"])
        XCTAssertEqual("foo  bar baz".split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true), ["foo", " bar baz"])
        XCTAssertEqual("foo  bar baz".split(separator: " ", omittingEmptySubsequences: true), ["foo", "bar", "baz"])
    }

    func testTrim() {
        XCTAssertEqual(" left space".trim(), "left space")
        XCTAssertEqual("left space".trim(), "left space")
        XCTAssertEqual("right space ".trim(), "right space")
        XCTAssertEqual("right space".trim(), "right space")
        XCTAssertEqual("  left and right ".trim(), "left and right")
        XCTAssertEqual("left and right".trim(), "left and right")
        XCTAssertEqual(" ,multiple characters ".trim([" ", ","]), "multiple characters")
        XCTAssertEqual("multiple characters".trim([" ", ","]), "multiple characters")
    }

    func testIndex() {
        let string = "A test string."
        XCTAssertEqual(string.index(of: "A"), string.startIndex)
        XCTAssertEqual(string.index(of: "test"), string.characters.index(of: "t"))
        XCTAssertEqual(string.index(of: "A test string."), string.characters.index(of: "A"))
    }

    func testContains() {
        let string = "A test string."
        XCTAssertTrue(string.contains(substring: "A"))
        XCTAssertTrue(string.contains(substring: " test"))
        XCTAssertTrue(string.contains(substring: "st st"))
        XCTAssertTrue(string.contains(substring: "A test string."))
        XCTAssertFalse(string.contains(substring: "A test string. "))
        XCTAssertFalse(string.contains(substring: "huehue"))
    }

    func testPercentEncodedInit() {
        XCTAssertEqual(try String(percentEncoded: "abc"), "abc")
        XCTAssertEqual(try String(percentEncoded: "%0A"), "\n")
        XCTAssertEqual(try String(percentEncoded: "jo%C3%A3o"), "joão")
        XCTAssertEqual(try String(percentEncoded: "%F0%9F%92%A9"), "💩")
        XCTAssertEqual(try String(percentEncoded: "foo%20bar"), "foo bar")
        XCTAssertEqual(try String(percentEncoded: "foo+bar"), "foo bar")
        XCTAssertThrowsError(try String(percentEncoded: "foo%"))
        XCTAssertThrowsError(try String(percentEncoded: "foo%A"))
        XCTAssertThrowsError(try String(percentEncoded: "foo%ZZ"))
        XCTAssertThrowsError(try String(percentEncoded: "%00%FF%FF%00"))
    }

    func testURLQueryPercentEncoding() {
        XCTAssertEqual("abc".percentEncoded(allowing: .uriQueryAllowed), "abc")
        XCTAssertEqual("joão".percentEncoded(allowing: .uriQueryAllowed), "jo%C3%A3o")
        XCTAssertEqual("💩".percentEncoded(allowing: .uriQueryAllowed), "%F0%9F%92%A9")
        XCTAssertEqual("foo bar".percentEncoded(allowing: .uriQueryAllowed), "foo%20bar")
        XCTAssertEqual("foo\nbar".percentEncoded(allowing: .uriQueryAllowed), "foo%0Abar")
    }

    func testUTF8URLQueryPercentEncoding() {
        XCTAssertEqual("abc".percentEncoded(allowing: UTF8.uriQueryAllowed), "abc")
        XCTAssertEqual("joão".percentEncoded(allowing: UTF8.uriQueryAllowed), "jo%C3%A3o")
        XCTAssertEqual("💩".percentEncoded(allowing: UTF8.uriQueryAllowed), "%F0%9F%92%A9")
        XCTAssertEqual("foo bar".percentEncoded(allowing: UTF8.uriQueryAllowed), "foo%20bar")
        XCTAssertEqual("foo\nbar".percentEncoded(allowing: UTF8.uriQueryAllowed), "foo%0Abar")
    }
}

extension StringTests {
    public static var allTests: [(String, (StringTests) -> () throws -> Void)] {
        return [
            ("testCString", testCString),
            ("testCapitalization", testCapitalization),
            ("testSplit", testSplit),
            ("testTrim", testTrim),
            ("testIndex", testIndex),
            ("testContains", testContains),
            ("testPercentEncodedInit", testPercentEncodedInit),
            ("testURLQueryPercentEncoding", testURLQueryPercentEncoding),
            ("testUTF8URLQueryPercentEncoding", testUTF8URLQueryPercentEncoding),
        ]
    }
}
