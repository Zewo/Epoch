#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import XCTest
@testable import File

public class FileTests : XCTestCase {
    func testReadWrite() throws {
        let deadline = 2.seconds.fromNow()
        var buffer: Buffer
        let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)

        try file.write("abc", deadline: deadline)
        try file.flush(deadline: deadline)
        XCTAssertEqual(try file.cursorPosition(), 3)
        _ = try file.seek(cursorPosition: 0)
        buffer = try file.read(upTo: 3, deadline: deadline)
        XCTAssertEqual(buffer.count, 3)
        XCTAssertEqual(buffer, Buffer("abc"))
        XCTAssertFalse(file.cursorIsAtEndOfFile)
        buffer = try file.read(upTo: 3, deadline: deadline)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertTrue(file.cursorIsAtEndOfFile)
        _ = try file.seek(cursorPosition: 0)
        XCTAssertFalse(file.cursorIsAtEndOfFile)
        _ = try file.seek(cursorPosition: 3)
        XCTAssertFalse(file.cursorIsAtEndOfFile)
        buffer = try file.read(upTo: 6, deadline: deadline)
        XCTAssertEqual(buffer.count, 0)
        XCTAssertTrue(file.cursorIsAtEndOfFile)
    }

    func testReadAllFile() throws {
        let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)
        let word = "hello"
        try file.write(word, deadline: 1.second.fromNow())
        try file.flush(deadline: 1.second.fromNow())
        _ = try file.seek(cursorPosition: 0)
        let buffer = try file.readAll(deadline: 1.second.fromNow())
        XCTAssert(buffer.count == word.utf8.count)
    }

    func testStaticMethods() throws {
        let filePath = "/tmp/zewo-test-file"
        let baseDirectoryPath = "/tmp/zewo"
        let directoryPath = baseDirectoryPath + "/test/dir/"
        let file = try File(path: filePath, mode: .truncateWrite)
        XCTAssertTrue(File.fileExists(path: filePath))
        XCTAssertFalse(File.isDirectory(path: filePath))
        let word = "hello"
        try file.write(word, deadline: 1.second.fromNow())
        try file.flush(deadline: 1.second.fromNow())
        file.close()
        try File.removeFile(path: filePath)
        XCTAssertThrowsError(try File.removeFile(path: filePath))
        XCTAssertFalse(File.fileExists(path: filePath))
        XCTAssertFalse(File.isDirectory(path: filePath))

        try File.createDirectory(path: baseDirectoryPath)
        XCTAssertThrowsError(try File.createDirectory(path: baseDirectoryPath))
        XCTAssertEqual(try File.contentsOfDirectory(path: baseDirectoryPath), [])
        XCTAssertTrue(File.fileExists(path: baseDirectoryPath))
        XCTAssertTrue(File.isDirectory(path: baseDirectoryPath))
        try File.removeDirectory(path: baseDirectoryPath)
        XCTAssertThrowsError(try File.removeDirectory(path: baseDirectoryPath))
        XCTAssertThrowsError(try File.contentsOfDirectory(path: baseDirectoryPath))
        XCTAssertFalse(File.fileExists(path: baseDirectoryPath))
        XCTAssertFalse(File.isDirectory(path: baseDirectoryPath))

        try File.createDirectory(path: directoryPath, withIntermediateDirectories: true)
        XCTAssertEqual(try File.contentsOfDirectory(path: baseDirectoryPath), ["test"])
        XCTAssertTrue(File.fileExists(path: directoryPath))
        XCTAssertTrue(File.isDirectory(path: directoryPath))
        try File.removeDirectory(path: baseDirectoryPath)
        XCTAssertThrowsError(try File.changeWorkingDirectory(path: baseDirectoryPath))
        XCTAssertFalse(File.fileExists(path: baseDirectoryPath))
        XCTAssertFalse(File.isDirectory(path: baseDirectoryPath))

        let workingDirectory = File.workingDirectory
        try File.changeWorkingDirectory(path: workingDirectory)
        XCTAssertEqual(File.workingDirectory, workingDirectory)
    }

    func testFileSize() throws {
        let file = try File(path: "/tmp/zewo-test-file", mode: .truncateReadWrite)
        try file.write(Buffer("hello"), deadline: 1.second.fromNow())
        try file.flush(deadline: 1.second.fromNow())
        XCTAssertEqual(file.length, 5)
        try file.write(" world", deadline: 1.second.fromNow())
        try file.flush(deadline: 1.second.fromNow())
        XCTAssertEqual(file.length, 11)
        file.close()
        XCTAssertThrowsError(try file.readAll(deadline: 1.second.fromNow()))
    }

    func testZero() throws {
        let file = try File(path: "/dev/zero")
        let count = 4096
        let length = 256

        for _ in 0 ..< count {
            let buffer = try file.read(upTo: length, deadline: 1.second.fromNow())
            XCTAssertEqual(buffer.count, length)
        }
    }

    func testRandom() throws {
#if os(OSX)
        let file = try File(path: "/dev/random")
        let count = 4096
        let length = 256

        for _ in 0 ..< count {
            let buffer = try file.read(upTo: length, deadline: 1.second.fromNow())
            XCTAssertEqual(buffer.count, length)
        }
#endif
    }

    func testDropLastPathComponent() throws {
        XCTAssertEqual("/foo/bar//fuu///baz/".droppingLastPathComponent(), "/foo/bar/fuu")
        XCTAssertEqual("/".droppingLastPathComponent(), "/")
        XCTAssertEqual("/foo".droppingLastPathComponent(), "/")
        XCTAssertEqual("foo".droppingLastPathComponent(), "")
    }

    func testFixSlashes() throws {
        XCTAssertEqual("/foo/bar//fuu///baz/".fixingSlashes(stripTrailing: true), "/foo/bar/fuu/baz")
        XCTAssertEqual("/".fixingSlashes(stripTrailing: true), "/")
    }

    func testFileModeValues() {
        let modes: [FileMode: Int32] = [
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
            ("testReadAllFile", testReadAllFile),
            ("testStaticMethods", testStaticMethods),
            ("testFileSize", testFileSize),
            ("testZero", testZero),
            ("testRandom", testRandom),
            ("testDropLastPathComponent", testDropLastPathComponent),
            ("testFixSlashes", testFixSlashes),
            ("testFileModeValues", testFileModeValues),
        ]
    }
}
