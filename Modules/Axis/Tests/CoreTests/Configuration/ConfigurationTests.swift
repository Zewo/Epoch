import XCTest
@testable import Core

public class ConfigurationTests : XCTestCase {
    func testConfigurationErrorDescription() throws {
        XCTAssertEqual(String(describing: ConfigurationError.invalidArgument(description: "foo")), "foo")
    }

    func testLoadCommandLineArguments() throws {
        var arguments: [String]
        var parsed: Map

        arguments = ["app-name"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, nil)

        arguments = ["app-name", "-server.log", "-server.host", "127.0.0.1", "-server.port", "8080"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, ["server": ["log": true, "host": "127.0.0.1", "port": 8080]])

        arguments = ["app-name", "-server.host", "127.0.0.1", "-server.log", "-server.port", "8080"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, ["server": ["log": true, "host": "127.0.0.1", "port": 8080]])

        arguments = ["app-name", "-server.host", "127.0.0.1", "-server.port", "8080", "-server.log"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, ["server": ["log": true, "host": "127.0.0.1", "port": 8080]])

        arguments = ["app-name", "-server.log", "-server.port", "8080", "-server.host", "127.0.0.1"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, ["server": ["log": true, "host": "127.0.0.1", "port": 8080]])

        arguments = ["app-name", "-server.port", "8080", "-server.log", "-server.host", "127.0.0.1"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, ["server": ["log": true, "host": "127.0.0.1", "port": 8080]])

        arguments = ["app-name", "-server.port", "8080", "-server.host", "127.0.0.1", "-server.log"]
        parsed = try Configuration.commandLineArguments(arguments)
        XCTAssertEqual(parsed, ["server": ["log": true, "host": "127.0.0.1", "port": 8080]])

        arguments = ["app-name", "foo"]
        XCTAssertThrowsError(try Configuration.commandLineArguments(arguments))

        arguments = ["app-name", "-foo", "bar", "baz"]
        XCTAssertThrowsError(try Configuration.commandLineArguments(arguments))

        arguments = ["app-name", "-foo", "-bar", "baz", "buh"]
        XCTAssertThrowsError(try Configuration.commandLineArguments(arguments))
    }

    func testParseValues() throws {
        XCTAssertEqual(Configuration.parse(value: ""), "")
        XCTAssertEqual(Configuration.parse(value: "NULL"), nil)
        XCTAssertEqual(Configuration.parse(value: "Null"), nil)
        XCTAssertEqual(Configuration.parse(value: "null"), nil)
        XCTAssertEqual(Configuration.parse(value: "NIL"), nil)
        XCTAssertEqual(Configuration.parse(value: "Nil"), nil)
        XCTAssertEqual(Configuration.parse(value: "nil"), nil)
        XCTAssertEqual(Configuration.parse(value: "1964"), 1964)
        XCTAssertEqual(Configuration.parse(value: "4.20"), 4.2)
        XCTAssertEqual(Configuration.parse(value: "TRUE"), true)
        XCTAssertEqual(Configuration.parse(value: "True"), true)
        XCTAssertEqual(Configuration.parse(value: "true"), true)
        XCTAssertEqual(Configuration.parse(value: "FALSE"), false)
        XCTAssertEqual(Configuration.parse(value: "False"), false)
        XCTAssertEqual(Configuration.parse(value: "false"), false)
        XCTAssertEqual(Configuration.parse(value: "foo"), "foo")
    }
}

extension ConfigurationTests {
    public static var allTests: [(String, (ConfigurationTests) -> () throws -> Void)] {
        return [
            ("testConfigurationErrorDescription", testConfigurationErrorDescription),
            ("testLoadCommandLineArguments", testLoadCommandLineArguments),
            ("testParseValues", testParseValues),
        ]
    }
}
