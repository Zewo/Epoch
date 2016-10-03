import XCTest
@testable import AxisTests

XCTMain([
    testCase(JSONTests.allTests),
    testCase(LoggerTests.allTests),
    testCase(InternalTests.allTests),
    testCase(MapConvertibleTests.allTests),
    testCase(MapTests.allTests),
    testCase(StringTests.allTests),
    testCase(URLEncodedFormParserTests.allTests),
])
