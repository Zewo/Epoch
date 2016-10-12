import XCTest
@testable import WebSocket

public class SHA1Tests : XCTestCase {
    func testSHA1() {
        let data = Array("sha1".utf8)
        let hash = sha1(data)

        var hexString = ""
        for byte in hash {
            hexString += String(format: "%02x", UInt(byte))
        }

        XCTAssertEqual(hexString, "415ab40ae9b7cc4e66d6769cb2c08106e8293b48")
    }

}

extension SHA1Tests {
    public static var allTests: [(String, (SHA1Tests) -> () throws -> Void)] {
        return [
            ("testSHA1", testSHA1),
        ]
    }
}
