import XCTest
import Axis
@testable import WebSocket

public class FrameTests : XCTestCase {
    func testMaskPong() {
        let maskKey = Buffer([0x39, 0xfa, 0xab, 0x35])
        let frame = Frame(opCode: .pong, data: Buffer(), maskKey: maskKey)
        let data = frame.data
        var pass = Buffer()
        pass.append(0b10001010)
        pass.append(0b10000000)
        pass.append(maskKey)
        XCTAssert(data == pass, "Frame does not match with pong case")
    }

    func testMaskText() {
        let maskKey = Buffer([0x39, 0xfa, 0xab, 0x35])
        let frame = Frame(opCode: .text, data: "Hello", maskKey: maskKey)
        let data = frame.data
        let pass = Buffer([0x81, 0x85, 0x39, 0xfa, 0xab, 0x35, 0x71, 0x9f, 0xc7, 0x59, 0x56])
        XCTAssert(data == pass, "Frame does not match with text case")
    }
}

extension FrameTests {
    public static var allTests: [(String, (FrameTests) -> () throws -> Void)] {
        return [
            ("testMaskPong", testMaskPong),
            ("testMaskText", testMaskText),
        ]
    }
}
