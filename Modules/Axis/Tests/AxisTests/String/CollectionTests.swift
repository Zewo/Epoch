import XCTest
@testable import Axis

public class CollectionTests : XCTestCase {
    func testIndexOf() {
        XCTAssertEqual([1, 1, 2, 3, 5, 8, 13, 21].index(of: [5, 8, 13]), 4)
        XCTAssertEqual(["Eat", "some", "more", "of", "these", "soft", "French", "buns"].index(of: ["French", "buns"]), 6)
        
        XCTAssertEqual([1, 0, 1, 0, 1].index(of: [0, 1]), 1)
        XCTAssertEqual(["loves", "me", "loves", "me", "not", "loves", "me"].index(of: ["loves", "me"]), 0)

        XCTAssertNil([1, 1, 2, 3, 5, 8, 13, 21].index(of: [2, 5, 8, 13]))
        XCTAssertNil(["Eat", "some", "more", "of", "these", "soft", "French", "buns"].index(of: ["some", "tea"]))

        XCTAssertNil([1, 1, 2, 3].index(of: [1, 1, 2, 3, 5]))
        XCTAssertNil(["Eat", "some"].index(of: ["Eat", "some", "more"]))
    }
}

extension CollectionTests {
    public static var allTests: [(String, (CollectionTests) -> () throws -> Void)] {
        return [
            ("testIndexOf", testIndexOf),
        ]
    }
}
