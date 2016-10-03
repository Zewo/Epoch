import XCTest
@testable import CoreTests

XCTMain([
    testCase(JSONTests.allTests),
    testCase(LoggerTests.allTests),
    testCase(InternalTests.allTests),
    testCase(MapConvertibleTests.allTests),
    testCase(MapTests.allTests),
    testCase(StringTests.allTests),
    testCase(URLEncodedFormParserTests.allTests),
])
