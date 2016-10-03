import XCTest
@testable import Core

public class JSONTests : XCTestCase {
    func testJSON() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer(ordering: true)

        let data = Data("{\"array\":[true,-4.2,-1969,null,\"hey! 😊\"],\"boolean\":false,\"dictionaryOfEmptyStuff\":{\"emptyArray\":[],\"emptyDictionary\":{},\"emptyString\":\"\"},\"double\":4.2,\"integer\":1969,\"null\":null,\"string\":\"yoo! 😎\"}")

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

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, data)
    }

    func testNumberWithExponent() throws {
        let parser = JSONMapParser()
        let data = Data("[1E3]")
        let map: Map = [1_000]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testNumberWithNegativeExponent() throws {
        let parser = JSONMapParser()
        let data = Data("[1E-3]")
        let map: Map = [1E-3]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testWhitespaces() throws {
        let parser = JSONMapParser()
        let data = Data("[ \n\t\r1 \n\t\r]")
        let map: Map = [1]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testNumberStartingWithZero() throws {
        let parser = JSONMapParser()
        let data = Data("[0001000]")
        let map: Map = [1000]
        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)
    }

    func testEscapedSlash() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data = Data("{\"foo\":\"\\\"\"}")

        let map: Map = [
            "foo": "\""
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, data)
    }

    func testSmallDictionary() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data = Data("{\"foo\":\"bar\",\"fuu\":\"baz\"}")

        let map: Map = [
            "foo": "bar",
            "fuu": "baz",
        ]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssert(serialized == data || serialized == Data("{\"fuu\":\"baz\",\"foo\":\"bar\"}"))
    }

    func testInvalidMap() throws {
        let serializer = JSONMapSerializer()

        let map: Map = [
            "foo": .data(Data("yo!"))
        ]

        var called = false

        do {
            _ = try serializer.serialize(map)
            XCTFail("Should've throwed error")
        } catch {
            called = true
        }
        
        XCTAssert(called)
    }

    func testEscapedEmoji() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data = Data("[\"\\ud83d\\ude0e\"]")
        let map: Map = ["😎"]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, Data("[\"😎\"]"))
    }

    func testEscapedSymbol() throws {
        let parser = JSONMapParser()
        let serializer = JSONMapSerializer()

        let data = Data("[\"\\u221e\"]")
        let map: Map = ["∞"]

        let parsed = try parser.parse(data)
        XCTAssertEqual(parsed, map)

        let serialized = try serializer.serialize(map)
        XCTAssertEqual(serialized, Data("[\"∞\"]"))
    }

    func testFailures() throws {
        let parser = JSONMapParser()
        var data: Data

        data = Data("")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("nudes")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("bar")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("{}foo")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\u")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud8")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\u")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\ud")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\ude")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\ude0")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\ude0e")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\ud83d\\u0000")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\u0000\\u0000")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\u0000\\ude0e")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("\"\\uGGGG\\uGGGG")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("0F")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("-0F")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("-09F")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("999999999999999998")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("999999999999999999")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("9999999999999999990")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("9999999999999999999")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("9.")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("0E")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("{\"foo\"}")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("{\"foo\":\"bar\"\"fuu\"}")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("{1969}")
        XCTAssertThrowsError(try parser.parse(data))
        data = Data("[\"foo\"\"bar\"]")
        XCTAssertThrowsError(try parser.parse(data))
    }

    func testDescription() throws {
        XCTAssertEqual(String(describing: JSONMapParseError.unexpectedTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "UnexpectedTokenError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.insufficientTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InsufficientTokenError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.extraTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "ExtraTokenError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.nonStringKeyError(reason: "foo", lineNumber: 0, columnNumber: 0)), "NonStringKeyError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.invalidStringError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InvalidStringError[Line: 0, Column: 0]: foo")
        XCTAssertEqual(String(describing: JSONMapParseError.invalidNumberError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InvalidNumberError[Line: 0, Column: 0]: foo")
    }
}

extension JSONTests {
    public static var allTests: [(String, (JSONTests) -> () throws -> Void)] {
        return [
            ("testJSON", testJSON),
            ("testNumberWithExponent", testNumberWithExponent),
            ("testNumberWithNegativeExponent", testNumberWithNegativeExponent),
            ("testWhitespaces", testWhitespaces),
            ("testNumberStartingWithZero", testNumberStartingWithZero),
            ("testEscapedSlash", testEscapedSlash),
            ("testSmallDictionary", testSmallDictionary),
            ("testInvalidMap", testInvalidMap),
            ("testEscapedEmoji", testEscapedEmoji),
            ("testEscapedSymbol", testEscapedSymbol),
            ("testFailures", testFailures),
            ("testDescription", testDescription),
        ]
    }
}
