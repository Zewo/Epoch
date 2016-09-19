import XCTest
import RethinkDBTests

XCTMain([
     testCase(ConnectionTests.allTests),
     testCase(ReqlAstTests.allTests)
])
