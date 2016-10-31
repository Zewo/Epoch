#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import File

public class FileDescriptorStreamTests : XCTestCase {
    func testZero() throws {
        let file = try FileDescriptorStream(path: "/dev/zero")
        let count = 4096
        let length = 256

        for _ in 0 ..< count {
            let buffer = try file.read(upTo: length, deadline: 1.second.fromNow())
            XCTAssertEqual(buffer.count, length)
        }
    }

    func testRandom() throws {
        #if os(OSX)
            let file = try FileDescriptorStream(path: "/dev/random")
            let count = 4096
            let length = 256

            for _ in 0 ..< count {
                let buffer = try file.read(upTo: length, deadline: 1.second.fromNow())
                XCTAssertEqual(buffer.count, length)
            }
        #endif
    }
}

extension FileDescriptorStreamTests {
    public static var allTests: [(String, (FileDescriptorStreamTests) -> () throws -> Void)] {
        return [
            ("testZero", testZero),
            ("testRandom", testRandom),
        ]
    }
}
