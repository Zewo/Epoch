import XCTest
@testable import Axis

public class JSONTests : XCTestCase {
    func testJSON() throws {
        let buffer = Buffer("{\"array\":[true,-4.2,-1969,null,\"hey! 😊\"],\"boolean\":false,\"dictionaryOfEmptyStuff\":{\"emptyArray\":[],\"emptyDictionary\":{},\"emptyString\":\"\"},\"double\":4.2,\"integer\":1969,\"null\":null,\"string\":\"yoo! 😎\"}")

        let map: Map = [
            "array": [
                true,
                -4.2,
                -1969,
                nil,
                "hey! 😊",
            ],
            "boolean": false,
            "dictionaryOfEmptyStuff": [
                "emptyArray": [],
                "emptyDictionary": [:],
                "emptyString": ""
            ],
            "double": 4.2,
            "integer": 1969,
            "null": nil,
            "string": "yoo! 😎",
        ]

        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)

        let serializer = JSONMapSerializer(ordering: true)
        try serializer.serialize(map) { serializedBuffer in
            XCTAssertEqual(Buffer(serializedBuffer), buffer)
        }
    }

    func testNumberWithExponent() throws {
        let buffer = Buffer("[1E3]")
        let map: Map = [1_000.0]
        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)
    }

    func testNumberWithNegativeExponent() throws {
        let buffer = Buffer("[1E-3]")
        let map: Map = [1E-3]
        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)
    }

    func testWhitespaces() throws {
        let buffer = Buffer("[ \n\t\r1 \n\t\r]")
        let map: Map = [1]
        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)
    }

    func testEscapedSlash() throws {
        let buffer = Buffer("{\"foo\":\"\\\"\"}")

        let map: Map = [
            "foo": "\""
        ]

        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)

        let serialized = try JSONMapSerializer.serialize(map)
        XCTAssertEqual(serialized, buffer)
    }

    func testSmallDictionary() throws {
        let buffer = Buffer("{\"foo\":\"bar\",\"fuu\":\"baz\"}")

        let map: Map = [
            "foo": "bar",
            "fuu": "baz",
        ]

        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)

        let serialized = try JSONMapSerializer.serialize(map)
        XCTAssert(serialized == buffer || serialized == Buffer("{\"fuu\":\"baz\",\"foo\":\"bar\"}"))
    }

    func testInvalidMap() throws {
        let map: Map = [
            "foo": .buffer(Buffer("yo!"))
        ]

        XCTAssertThrowsError(try JSONMapSerializer.serialize(map))
    }

    func testEscapedEmoji() throws {
        let buffer = Buffer("[\"\\ud83d\\ude0e\"]")
        let map: Map = ["😎"]

        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)

        let serialized = try JSONMapSerializer.serialize(map)
        XCTAssertEqual(serialized, Buffer("[\"😎\"]"))
    }

    func testEscapedSymbol() throws {
        let buffer = Buffer("[\"\\u221e\"]")
        let map: Map = ["∞"]

        let parsed = try JSONMapParser.parse(buffer)
        XCTAssertEqual(parsed, map)

        let serialized = try JSONMapSerializer.serialize(map)
        XCTAssertEqual(serialized, Buffer("[\"∞\"]"))
    }

    func testFailures() throws {
        var buffer: Buffer

        buffer = Buffer("")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("nudes")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("bar")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("{}foo")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\u")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud8")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\u")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\ud")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\ude")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\ude0")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\ude0e")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\ud83d\\u0000")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\u0000\\u0000")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\u0000\\ude0e")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("\"\\uGGGG\\uGGGG")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("0F")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("-0F")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("-09F")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("9999999999999999990")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("9999999999999999999")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("9.")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("0E")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("{\"foo\"}")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("{\"foo\":\"bar\"\"fuu\"}")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("{1969}")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
        buffer = Buffer("[\"foo\"\"bar\"]")
        XCTAssertThrowsError(try JSONMapParser.parse(buffer))
    }
}

extension JSONTests {
    public static var allTests: [(String, (JSONTests) -> () throws -> Void)] {
        return [
            ("testJSON", testJSON),
            ("testNumberWithExponent", testNumberWithExponent),
            ("testNumberWithNegativeExponent", testNumberWithNegativeExponent),
            ("testWhitespaces", testWhitespaces),
            ("testEscapedSlash", testEscapedSlash),
            ("testSmallDictionary", testSmallDictionary),
            ("testInvalidMap", testInvalidMap),
            ("testEscapedEmoji", testEscapedEmoji),
            ("testEscapedSymbol", testEscapedSymbol),
            ("testFailures", testFailures),
        ]
    }
}
