import XCTest
@testable import WebSocket

public class FrameTests: XCTestCase {
    func testMaskPong() {
        let maskKey = Data([0x39, 0xfa, 0xab, 0x35])
        let frame = Frame(opCode: .pong, data: [], maskKey: maskKey)
        let data = frame.data
        var pass = Data()
        pass.append(0b10001010)
        pass.append(0b10000000)
        pass += maskKey
        pass += []
        XCTAssert(data == pass, "Frame does not match with pong case")
    }

    func testMaskText() {
      let maskKey = Data([0x39, 0xfa, 0xab, 0x35])
      let frame = Frame(opCode: .text, data: "Hello", maskKey: maskKey)
      let data = frame.data
      let pass = Data([0x81, 0x85, 0x39, 0xfa, 0xab, 0x35, 0x71, 0x9f, 0xc7, 0x59, 0x56])
      XCTAssert(data == pass, "Frame does not match with text case")
    }
}

extension FrameTests {
    static var allTests: [(String, (FrameTests) -> () throws -> Void)] {
        return [
            ("testMaskPong", testMaskPong),
            ("testMaskText", testMaskText),
        ]
    }
}
