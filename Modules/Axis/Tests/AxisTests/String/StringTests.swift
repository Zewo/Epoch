import XCTest
@testable import Axis

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

    func testUTF8URLQueryPercentEncoding() {
        XCTAssertEqual("abc".percentEncoded(allowing: UnicodeScalars.uriQueryAllowed.utf8), "abc")
        XCTAssertEqual("joão".percentEncoded(allowing: UnicodeScalars.uriQueryAllowed.utf8), "jo%C3%A3o")
        XCTAssertEqual("💩".percentEncoded(allowing: UnicodeScalars.uriQueryAllowed.utf8), "%F0%9F%92%A9")
        XCTAssertEqual("foo bar".percentEncoded(allowing: UnicodeScalars.uriQueryAllowed.utf8), "foo%20bar")
        XCTAssertEqual("foo\nbar".percentEncoded(allowing: UnicodeScalars.uriQueryAllowed.utf8), "foo%0Abar")
    }

    func testUnicode2UTF8Mapping() {
        func testUTFMappping(of scalars: UnicodeScalars) {
            for scalar in scalars {
                UTF8.encode(scalar) {
                    XCTAssertTrue(scalars.utf8.contains($0))
                }
            }

            var decoder = UTF8()

            for codeUnit in scalars.utf8 {
                var input = [codeUnit].makeIterator()
                switch decoder.decode(&input) {
                case .scalarValue(let scalar):
                    XCTAssertTrue(scalars.contains(scalar))
                default:
                    XCTFail("Incomplete mapping between scalars and UTF8 code units")
                }
            }
        }

        testUTFMappping(of: UnicodeScalars.whitespaceAndNewline)
        testUTFMappping(of: UnicodeScalars.digits)
        testUTFMappping(of: UnicodeScalars.uriQueryAllowed)
        testUTFMappping(of: UnicodeScalars.uriFragmentAllowed)
        testUTFMappping(of: UnicodeScalars.uriPathAllowed)
        testUTFMappping(of: UnicodeScalars.uriHostAllowed)
        testUTFMappping(of: UnicodeScalars.uriPasswordAllowed)
        testUTFMappping(of: UnicodeScalars.uriUserAllowed)
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
            ("testUTF8URLQueryPercentEncoding", testUTF8URLQueryPercentEncoding),
            ("testUnicode2UTF8Mapping", testUnicode2UTF8Mapping),
        ]
    }
}
