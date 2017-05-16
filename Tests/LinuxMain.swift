import XCTest
import IOTests
import CoreTests
    
XCTMain([
    testCase(IPTests.allTests),
    testCase(TCPTests.allTests),
    testCase(SystemErrorTests.allTests),
])
