//import XCTest
//@testable import Core
//
//public class JSONTests : XCTestCase {
//    func testJSON() throws {
//        let buffer = Buffer("{\"array\":[true,-4.2,-1969,null,\"hey! 😊\"],\"boolean\":false,\"dictionaryOfEmptyStuff\":{\"emptyArray\":[],\"emptyDictionary\":{},\"emptyString\":\"\"},\"double\":4.2,\"integer\":1969,\"null\":null,\"string\":\"yoo! 😎\"}")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let serializerStream = BufferStream()
//        let serializer = JSONMapSerializer(stream: serializerStream, ordering: true)
//
//        let map: Map = [
//            "array": [
//                true,
//                -4.2,
//                -1969,
//                nil,
//                "hey! 😊",
//            ],
//            "boolean": false,
//            "dictionaryOfEmptyStuff": [
//                "emptyArray": [],
//                "emptyDictionary": [:],
//                "emptyString": ""
//            ],
//            "double": 4.2,
//            "integer": 1969,
//            "null": nil,
//            "string": "yoo! 😎",
//        ]
//
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//
//        try serializer.serialize(map, deadline: .never)
//        XCTAssertEqual(serializerStream.buffer, buffer)
//    }
//
//    func testNumberWithExponent() throws {
//        let buffer = Buffer("[1E3]")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let map: Map = [1_000]
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//    }
//
//    func testNumberWithNegativeExponent() throws {
//        let buffer = Buffer("[1E-3]")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let map: Map = [1E-3]
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//    }
//
//    func testWhitespaces() throws {
//        let buffer = Buffer("[ \n\t\r1 \n\t\r]")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let map: Map = [1]
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//    }
//
//    func testNumberStartingWithZero() throws {
//        let buffer = Buffer("[0001000]")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let map: Map = [1000]
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//    }
//
//    func testEscapedSlash() throws {
//        let buffer = Buffer("{\"foo\":\"\\\"\"}")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let serializerStream = BufferStream()
//        let serializer = JSONMapSerializer(stream: serializerStream)
//
//        let map: Map = [
//            "foo": "\""
//        ]
//
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//
//        try serializer.serialize(map, deadline: .never)
//        XCTAssertEqual(serializerStream.buffer, buffer)
//    }
//
//    func testSmallDictionary() throws {
//        let buffer = Buffer("{\"foo\":\"bar\",\"fuu\":\"baz\"}")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let serializerStream = BufferStream()
//        let serializer = JSONMapSerializer(stream: serializerStream)
//
//        let map: Map = [
//            "foo": "bar",
//            "fuu": "baz",
//        ]
//
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//
//        try serializer.serialize(map, deadline: .never)
//        let serialized = serializerStream.buffer
//        XCTAssert(serialized == buffer || serialized == Buffer("{\"fuu\":\"baz\",\"foo\":\"bar\"}"))
//    }
//
//    func testInvalidMap() throws {
//        let serializerStream = BufferStream()
//        let serializer = JSONMapSerializer(stream: serializerStream)
//
//        let map: Map = [
//            "foo": .buffer(Buffer("yo!"))
//        ]
//
//        XCTAssertThrowsError(try serializer.serialize(map, deadline: .never))
//    }
//
//    func testEscapedEmoji() throws {
//        let buffer = Buffer("[\"\\ud83d\\ude0e\"]")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let serializerStream = BufferStream()
//        let serializer = JSONMapSerializer(stream: serializerStream)
//
//        let map: Map = ["😎"]
//
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//
//        try serializer.serialize(map, deadline: .never)
//        let serialized = serializerStream.buffer
//        XCTAssertEqual(serialized, Buffer("[\"😎\"]"))
//    }
//
//    func testEscapedSymbol() throws {
//        let buffer = Buffer("[\"\\u221e\"]")
//        let parserStream = BufferStream(buffer: buffer)
//        let parser = JSONMapParser(stream: parserStream)
//        let serializerStream = BufferStream()
//        let serializer = JSONMapSerializer(stream: serializerStream)
//
//        let map: Map = ["∞"]
//
//        let parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, map)
//
//        try serializer.serialize(map, deadline: .never)
//        let serialized = serializerStream.buffer
//        XCTAssertEqual(serialized, Buffer("[\"∞\"]"))
//    }
//
//    func testFailures() throws {
//        var buffer: Buffer
//        var parserStream: BufferStream
//        var parser: JSONMapParser
//        var parsed: Map
//
//        buffer = Buffer("")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("nudes")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("bar")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("{}foo")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, [:])
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\u")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud8")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\u")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\ud")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\ude")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\ude0")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\ude0e")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\ud83d\\u0000")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\u0000\\u0000")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\u0000\\ude0e")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("\"\\uGGGG\\uGGGG")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("0F")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, 0)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("-0F")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, 0)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("-09F")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        parsed = try parser.parse(deadline: .never)
//        XCTAssertEqual(parsed, -9)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("999999999999999998")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("999999999999999999")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("9999999999999999990")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("9999999999999999999")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("9.")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("0E")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("{\"foo\"}")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("{\"foo\":\"bar\"\"fuu\"}")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("{1969}")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//        buffer = Buffer("[\"foo\"\"bar\"]")
//        parserStream = BufferStream(buffer: buffer)
//        parser = JSONMapParser(stream: parserStream)
//        XCTAssertThrowsError(try parser.parse(deadline: .never))
//    }
//
//    func testDescription() throws {
//        XCTAssertEqual(String(describing: JSONMapParserError.unexpectedTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "UnexpectedTokenError[Line: 0, Column: 0]: foo")
//        XCTAssertEqual(String(describing: JSONMapParserError.insufficientTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InsufficientTokenError[Line: 0, Column: 0]: foo")
//        XCTAssertEqual(String(describing: JSONMapParserError.extraTokenError(reason: "foo", lineNumber: 0, columnNumber: 0)), "ExtraTokenError[Line: 0, Column: 0]: foo")
//        XCTAssertEqual(String(describing: JSONMapParserError.nonStringKeyError(reason: "foo", lineNumber: 0, columnNumber: 0)), "NonStringKeyError[Line: 0, Column: 0]: foo")
//        XCTAssertEqual(String(describing: JSONMapParserError.invalidStringError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InvalidStringError[Line: 0, Column: 0]: foo")
//        XCTAssertEqual(String(describing: JSONMapParserError.invalidNumberError(reason: "foo", lineNumber: 0, columnNumber: 0)), "InvalidNumberError[Line: 0, Column: 0]: foo")
//    }
//}
//
//extension JSONTests {
//    public static var allTests: [(String, (JSONTests) -> () throws -> Void)] {
//        return [
//            ("testJSON", testJSON),
//            ("testNumberWithExponent", testNumberWithExponent),
//            ("testNumberWithNegativeExponent", testNumberWithNegativeExponent),
//            ("testWhitespaces", testWhitespaces),
//            ("testNumberStartingWithZero", testNumberStartingWithZero),
//            ("testEscapedSlash", testEscapedSlash),
//            ("testSmallDictionary", testSmallDictionary),
//            ("testInvalidMap", testInvalidMap),
//            ("testEscapedEmoji", testEscapedEmoji),
//            ("testEscapedSymbol", testEscapedSymbol),
//            ("testFailures", testFailures),
//            ("testDescription", testDescription),
//        ]
//    }
//}
