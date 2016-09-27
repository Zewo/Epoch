import XCTest
@testable import IP

public class IPTests : XCTestCase {
    func testErrorDescription() {
        XCTAssertEqual(String(describing: IPError.invalidPort), "Port number should be between 0 and 0xffff")
    }

    func testIPV4() throws {
        let ip = try IP(port: 5555, mode: .ipv4)
        XCTAssertEqual(ip.port, 5555)
    }

    func testIPV6() throws {
        let ip = try IP(port: 5555, mode: .ipv6)
        XCTAssertEqual(ip.port, 5555)
    }

    func testIPV4Prefered() throws {
        let ip = try IP(port: 5555, mode: .ipv4Prefered)
        XCTAssertEqual(ip.port, 5555)
    }

    func testIPV6Prefered() throws {
        let ip = try IP(port: 5555, mode: .ipv6Prefered)
        XCTAssertEqual(ip.port, 5555)
    }

    func testLocalIPV4() throws {
        let ip = try IP(address: "127.0.0.1", port: 5555, mode: .ipv4)
        XCTAssertEqual(String(describing: ip), "127.0.0.1")
        XCTAssertEqual(ip.port, 5555)
    }

    func testLocalIPV6() throws {
        let ip = try IP(address: "::1", port: 5555, mode: .ipv6)
        XCTAssertEqual(String(describing: ip), "::1")
        XCTAssertEqual(ip.port, 5555)
    }

    func testLocalIPV4Prefered() throws {
        let ip = try IP(address: "127.0.0.1", port: 5555, mode: .ipv4Prefered)
        XCTAssertEqual(String(describing: ip), "127.0.0.1")
        XCTAssertEqual(ip.port, 5555)
    }

    func testLocalIPV6Prefered() throws {
        let ip = try IP(address: "::1", port: 5555, mode: .ipv6Prefered)
        XCTAssertEqual(String(describing: ip), "::1")
        XCTAssertEqual(ip.port, 5555)
    }

    func testRemoteIPV4DNS() throws {
        let ip = try IP(address: "www.example.org", port: 80, mode: .ipv4, deadline: 30.seconds.fromNow())
        XCTAssertEqual(ip.family, .ipv4)
        XCTAssertEqual(ip.port, 80)
    }

    func testRemoteIPV4DNSTimeout() throws {
        XCTAssertThrowsError(try IP(address: "www.example.org", port: 80, mode: .ipv4, deadline: 1.millisecond.fromNow()))
    }

    func testRemoteIPV6DNSTimeout() throws {
        XCTAssertThrowsError(try IP(address: "www.example.org", port: 80, mode: .ipv6, deadline: 1.millisecond.fromNow()))
    }

    func testInvalidPortIPV4() throws {
        XCTAssertThrowsError(try IP(port: 70000, mode: .ipv4))
    }

    func testInvalidPortIPV6() throws {
        XCTAssertThrowsError(try IP(port: 70000, mode: .ipv6))
    }

    func testInvalidPortIPV4Prefered() throws {
        XCTAssertThrowsError(try IP(port: 70000, mode: .ipv4Prefered))
    }

    func testInvalidPortIPV6Prefered() throws {
        XCTAssertThrowsError(try IP(port: 70000, mode: .ipv6Prefered))
    }

    func testInvalidLocalIPV4() throws {
        XCTAssertThrowsError(try IP(address: "yo-yo ma", port: 5555, mode: .ipv4, deadline: 100.millisecond.fromNow()))
    }

    func testInvalidLocalIPV6() throws {
        XCTAssertThrowsError(try IP(address: "yo-yo ma", port: 5555, mode: .ipv6, deadline: 100.millisecond.fromNow()))
    }

    func testInvalidLocalIPV4Prefered() throws {
        XCTAssertThrowsError(try IP(address: "yo-yo ma", port: 5555, mode: .ipv4Prefered, deadline: 100.millisecond.fromNow()))
    }

    func testInvalidLocalIPV6Prefered() throws {
        XCTAssertThrowsError(try IP(address: "yo-yo ma", port: 5555, mode: .ipv6Prefered, deadline: 100.millisecond.fromNow()))
    }
}

extension IPTests {
    public static var allTests: [(String, (IPTests) -> () throws -> Void)] {
        return [
            ("testErrorDescription", testErrorDescription),
            ("testLocalIPV4", testLocalIPV4),
            ("testLocalIPV6", testLocalIPV6),
            ("testLocalIPV4Prefered", testLocalIPV4Prefered),
            ("testLocalIPV6Prefered", testLocalIPV6Prefered),
            ("testLocalIPV4", testLocalIPV4),
            ("testLocalIPV6", testLocalIPV6),
            ("testLocalIPV4Prefered", testLocalIPV4Prefered),
            ("testLocalIPV6Prefered", testLocalIPV6Prefered),
            ("testInvalidPortIPV4", testInvalidPortIPV4),
            ("testInvalidPortIPV6", testInvalidPortIPV6),
            ("testInvalidPortIPV4Prefered", testInvalidPortIPV4Prefered),
            ("testInvalidPortIPV6Prefered", testInvalidPortIPV6Prefered),
            ("testInvalidLocalIPV4", testInvalidLocalIPV4),
            ("testInvalidLocalIPV6", testInvalidLocalIPV6),
            ("testInvalidLocalIPV4Prefered", testInvalidLocalIPV4Prefered),
            ("testInvalidLocalIPV6Prefered", testInvalidLocalIPV6Prefered),
        ]
    }
}
