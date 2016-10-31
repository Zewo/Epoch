#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import File

public class FileTests : XCTestCase {
    func testReadWrite() throws {
        let deadline = 1.second.fromNow()
        var buffer: Buffer
        let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)

        try file.write("abc", deadline: deadline)
        try file.flush(deadline: deadline)
        XCTAssertEqual(try file.cursorPosition(), 3)
        _ = try file.seek(cursorPosition: 0)
        buffer = try file.read(upTo: 3, deadline: deadline)
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer, Buffer("abc"))
        buffer = try file.read(upTo: 3, deadline: deadline)
        XCTAssertEqual(buffer.count, 0)
        _ = try file.seek(cursorPosition: 0)
        _ = try file.seek(cursorPosition: 3)
        buffer = try file.read(upTo: 6, deadline: deadline)
        XCTAssertEqual(buffer.count, 0)
    }

    func testDrainFile() throws {
        let deadline = 1.second.fromNow()
        let file = try File(path: "/tmp/zewo-test-file2", mode: .truncateReadWrite)
        let word = "hello"
        try file.write(word, deadline: deadline)
        try file.flush(deadline: deadline)
        XCTAssertEqual(try file.seek(cursorPosition: 0), 0)
        let buffer = try file.drain(deadline: deadline)
        XCTAssert(buffer.count == word.utf8.count)
    }

    func testStaticMethods() throws {
        let filePath = "/tmp/zewo-test-file3"
        let baseDirectoryPath = "/tmp/zewo"
        let directoryPath = baseDirectoryPath + "/test/dir/"
        let file = try File(path: filePath, mode: .truncateWrite)
        XCTAssertTrue(File.fileExists(atPath: filePath))
        XCTAssertFalse(File.directoryExists(atPath: filePath))
        let word = "hello"
        try file.write(word, deadline: 1.second.fromNow())
        try file.flush(deadline: 1.second.fromNow())
        file.close()
        try File.removeItem(atPath: filePath)
        XCTAssertThrowsError(try File.removeItem(atPath: filePath))
        XCTAssertFalse(File.fileExists(atPath: filePath))
        XCTAssertFalse(File.directoryExists(atPath: filePath))

        try File.createDirectory(atPath: baseDirectoryPath)
        XCTAssertThrowsError(try File.createDirectory(atPath: baseDirectoryPath))
        XCTAssertEqual(try File.contentsOfDirectory(atPath: baseDirectoryPath), [])
        XCTAssertTrue(File.fileExists(atPath: baseDirectoryPath))
        XCTAssertTrue(File.directoryExists(atPath: baseDirectoryPath))
        try File.removeItem(atPath: baseDirectoryPath)
        XCTAssertThrowsError(try File.removeItem(atPath: baseDirectoryPath))
        XCTAssertThrowsError(try File.contentsOfDirectory(atPath: baseDirectoryPath))
        XCTAssertFalse(File.fileExists(atPath: baseDirectoryPath))
        XCTAssertFalse(File.directoryExists(atPath: baseDirectoryPath))

        try File.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        XCTAssertEqual(try File.contentsOfDirectory(atPath: baseDirectoryPath), ["test"])
        XCTAssertTrue(File.fileExists(atPath: directoryPath))
        XCTAssertTrue(File.directoryExists(atPath: directoryPath))
        try File.removeItem(atPath: baseDirectoryPath)
        XCTAssertThrowsError(try File.changeCurrentDirectory(path: baseDirectoryPath))
        XCTAssertFalse(File.fileExists(atPath: baseDirectoryPath))
        XCTAssertFalse(File.directoryExists(atPath: baseDirectoryPath))

        let workingDirectory = File.currentDirectoryPath
        try File.changeCurrentDirectory(path: workingDirectory)
        XCTAssertEqual(File.currentDirectoryPath, workingDirectory)
    }

    func testFileSize() throws {
        let deadline = 1.second.fromNow()
        let file = try File(path: "/tmp/zewo-test-file4", mode: .truncateReadWrite)
        try file.write(Buffer("hello"), deadline: deadline)
        try file.flush(deadline: deadline)
        XCTAssertEqual(try file.size(), 5)
        try file.write(" world", deadline: 1.second.fromNow())
        try file.flush(deadline: deadline)
        XCTAssertEqual(try file.size(), 11)
        file.close()
        XCTAssertThrowsError(try file.drain(deadline: deadline))
    }

    func testFileModeValues() {
        let modes: [File.Mode: Int32] = [
            .read: O_RDONLY,
            .createWrite: (O_WRONLY | O_CREAT | O_EXCL),
            .truncateWrite: (O_WRONLY | O_CREAT | O_TRUNC),
            .appendWrite: (O_WRONLY | O_CREAT | O_APPEND),
            .readWrite: (O_RDWR),
            .createReadWrite: (O_RDWR | O_CREAT | O_EXCL),
            .truncateReadWrite: (O_RDWR | O_CREAT | O_TRUNC),
            .appendReadWrite: (O_RDWR | O_CREAT | O_APPEND),
        ]
        for (mode, value) in modes {
            XCTAssertEqual(mode.value, value)
        }
    }
}

extension FileTests {
    public static var allTests: [(String, (FileTests) -> () throws -> Void)] {
        return [
            ("testReadWrite", testReadWrite),
            ("testDrainFile", testDrainFile),
            ("testStaticMethods", testStaticMethods),
            ("testFileSize", testFileSize),
            ("testFileModeValues", testFileModeValues),
        ]
    }
}
