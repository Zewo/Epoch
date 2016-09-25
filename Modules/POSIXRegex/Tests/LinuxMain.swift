#if os(Linux)

import XCTest
@testable import POSIXRegexTests

XCTMain([
    testCase(POSIXRegexTests.allTests)
])

#endif
