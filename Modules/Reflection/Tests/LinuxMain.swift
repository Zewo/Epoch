import XCTest
import ReflectionTests

XCTMain([
    testCase(InternalTests.allTests),
    testCase(MappableTests.allTests),
    testCase(PerformanceTests.allTests),
    testCase(PublicTests.allTests),
])
