import XCTest
import Venice
@testable import IO

public class IPTests: XCTestCase {
    let deadline: Deadline = .never
    
    func testErrorDescription() {
        XCTAssertEqual(String(describing: IPError.invalidPort), "Port number should be between 0 and 0xffff")
    }

    func testIPV4() throws {
        _ = try IP(port: 5555, mode: .ipv4)
    }

    func testIPV6() throws {
        _ = try IP(port: 5555, mode: .ipv6)
    }

    func testLocalIPV4() throws {
        _ = try IP(address: "127.0.0.1", port: 5555, mode: .ipv4, deadline: deadline)
    }

    func testLocalIPV6() throws {
        _ = try IP(address: "::1", port: 5555, mode: .ipv6, deadline: deadline)
    }

    func testRemoteIPV4() throws {
        let ip = try IP(address: "127.0.0.1", port: 5555, mode: .ipv4, deadline: 1.second.fromNow())
        XCTAssertEqual(String(describing: ip), "127.0.0.1")
    }

    func testRemoteIPV6() throws {
        _ = try IP(address: "::1", port: 5555, mode: .ipv6, deadline: 1.second.fromNow())
    }

    func testInvalidPortIPV4() throws {
        XCTAssertThrowsError(try IP(port: 70000, mode: .ipv4))
    }

    func testInvalidPortIPV6() throws {
        XCTAssertThrowsError(try IP(port: 70000, mode: .ipv6))
    }

    func testInvalidLocalIPV4() throws {
        XCTAssertThrowsError(try IP(address: "yo-yo ma", port: 5555, mode: .ipv4, deadline: deadline))
    }

    func testInvalidLocalIPV6() throws {
        XCTAssertThrowsError(try IP(address: "yo-yo ma", port: 5555, mode: .ipv6, deadline: deadline))
    }

    func testRemoteInvalidPortIPV4() throws {
        XCTAssertThrowsError(try IP(address: "127.0.0.1", port: 70000, mode: .ipv4, deadline: 1.second.fromNow()))
    }

    func testRemoteInvalidPortIPV6() throws {
        XCTAssertThrowsError(try IP(address: "::1", port: 70000, mode: .ipv6, deadline: 1.second.fromNow()))
    }
}

extension IPTests {
    public static var allTests: [(String, (IPTests) -> () throws -> Void)] {
        return [
            ("testErrorDescription", testErrorDescription),
            ("testLocalIPV4", testLocalIPV4),
            ("testLocalIPV6", testLocalIPV6),
            ("testLocalIPV4", testLocalIPV4),
            ("testLocalIPV6", testLocalIPV6),
            ("testRemoteIPV4", testRemoteIPV4),
            ("testRemoteIPV6", testRemoteIPV6),
            ("testInvalidPortIPV4", testInvalidPortIPV4),
            ("testInvalidPortIPV6", testInvalidPortIPV6),
            ("testInvalidLocalIPV4", testInvalidLocalIPV4),
            ("testInvalidLocalIPV6", testInvalidLocalIPV6),
            ("testRemoteInvalidPortIPV4", testRemoteInvalidPortIPV4),
            ("testRemoteInvalidPortIPV6", testRemoteInvalidPortIPV6),
        ]
    }
}
