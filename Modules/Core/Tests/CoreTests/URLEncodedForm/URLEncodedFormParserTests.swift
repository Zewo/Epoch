import XCTest
@testable import Core

public class URLEncodedFormParserTests : XCTestCase {
    func testSingleValue() throws {
        let buffer = Buffer("key=value")
        let urlEncodedForm = try URLEncodedFormParser().parse(buffer: buffer)

        XCTAssertEqual(urlEncodedForm.values.count, 1)
        XCTAssertEqual(urlEncodedForm.values["key"], "value")
    }

    func testMultipleValues() throws {
        let buffer = Buffer("key1=value1&key2=value2")
        let urlEncodedForm = try URLEncodedFormParser().parse(buffer: buffer)

        XCTAssertEqual(urlEncodedForm.values.count, 2)
        XCTAssertEqual(urlEncodedForm.values["key1"], "value1")
        XCTAssertEqual(urlEncodedForm.values["key2"], "value2")
    }

    func testEmptyValues() throws {
        let buffer = Buffer("key1=value1&empty1=&key2=value2&empty2=")
        let urlEncodedForm = try URLEncodedFormParser().parse(buffer: buffer)

        XCTAssertEqual(urlEncodedForm.values.count, 4)
        XCTAssertEqual(urlEncodedForm.values["key1"], "value1")
        XCTAssertEqual(urlEncodedForm.values["key2"], "value2")
        XCTAssertEqual(urlEncodedForm.values["empty1"], "")
        XCTAssertEqual(urlEncodedForm.values["empty2"], "")
    }

    func testMissingEqualSymbol() throws {
        var buffer = Buffer("key")
        XCTAssertNil(try? URLEncodedFormParser().parse(buffer: buffer))

        buffer = Buffer("key1&key2=value2")
        XCTAssertNil(try? URLEncodedFormParser().parse(buffer: buffer))

        buffer = Buffer("key1=value1&key2")
        XCTAssertNil(try? URLEncodedFormParser().parse(buffer: buffer))
    }

    func testPercentEncoding() throws {
        let buffer = Buffer("user%2Bemail=test%40example.com")
        let urlEncodedForm = try URLEncodedFormParser().parse(buffer: buffer)

        XCTAssertEqual(urlEncodedForm.values.count, 1)
        XCTAssertEqual(urlEncodedForm.values["user+email"], "test@example.com")
    }
}

extension URLEncodedFormParserTests {
    public static var allTests: [(String, (URLEncodedFormParserTests) -> () throws -> Void)] {
        return [
           ("testSingleValue", testSingleValue),
           ("testMultipleValues", testMultipleValues),
           ("testEmptyValues", testEmptyValues),
           ("testMissingEqualSymbol", testMissingEqualSymbol),
           ("testPercentEncoding", testPercentEncoding),
        ]
    }
}
