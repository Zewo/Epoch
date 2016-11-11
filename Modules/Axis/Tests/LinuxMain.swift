import XCTest
@testable import AxisTests

XCTMain([
    testCase(ConfigurationTests.allTests),
    testCase(JSONTests.allTests),
    testCase(LoggerTests.allTests),
    testCase(MapConvertibleTests.allTests),
    testCase(MapTests.allTests),
    testCase(StringTests.allTests),
    testCase(URLTests.allTests),
])
