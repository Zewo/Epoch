import XCTest
@testable import POSIXTests

XCTMain([
    testCase(POSIXTests.allTests),
    testCase(EnvironmentTests.allTests),
    testCase(ThreadTests.allTests),
    testCase(LockTests.allTests),
])
