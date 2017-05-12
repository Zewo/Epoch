import XCTest
import IOTests
import POSIXTests
    
XCTMain([
    testCase(IPTests.allTests),
    testCase(TCPTests.allTests),
    testCase(POSIXTests.allTests),
])
