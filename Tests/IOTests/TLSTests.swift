import XCTest
@testable import IO
@testable import Core
@testable import Venice

public class TLSTests: XCTestCase {
    var testsPath: String {
        var components = #file.components(separatedBy: "/")
        components.removeLast()
        return components.joined(separator: "/") + "/"
    }
    
    func testConnectionRefused() throws {
        let deadline = 1.minute.fromNow()
        let connection = try TLSStream(host: "127.0.0.1", port: 8005, deadline: deadline)
        XCTAssertThrowsError(try connection.open(deadline: deadline))
    }
    
    func testReadWriteClosedSocket() throws {
        let deadline = 5.seconds.fromNow()
        let port = 8006
        let channel = try Channel<Void>()
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 1, alignment: MemoryLayout<UInt8>.alignment)
        
        defer {
            buffer.deallocate()
        }
        
        let coroutine = try Coroutine {
            do {
                let host = try TLSHost(
                    port: port,
                    certificatePath: self.testsPath + "cert.pem",
                    keyPath: self.testsPath + "key.pem"
                )
                
                let stream = try host.accept(deadline: deadline)
                try channel.receive(deadline: deadline)
                try stream.close(deadline: deadline)
                XCTAssertThrowsError(try stream.write("123", deadline: deadline))
                XCTAssertThrowsError(try stream.read(buffer, deadline: deadline))
                try channel.receive(deadline: deadline)
            } catch {
                print(error)
                XCTFail("\(error)")
            }
        }
        
        let stream = try TLSStream(host: "127.0.0.1", port: port, deadline: deadline)
        try stream.open(deadline: deadline)
        try channel.send(deadline: deadline)
        try stream.close(deadline: deadline)
        XCTAssertThrowsError(try stream.close(deadline: deadline))
        XCTAssertThrowsError(try stream.write("123", deadline: deadline))
        XCTAssertThrowsError(try stream.read(buffer, deadline: deadline))
        try channel.send(deadline: deadline)
        coroutine.cancel()
    }
    
    func testClientServer() throws {
        let deadline = 1.minute.fromNow()
        let port = 8009
        let channel = try Channel<Void>()
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: 10, alignment: MemoryLayout<UInt8>.alignment)
        
        defer {
            buffer.deallocate()
        }
        
        let coroutine = try Coroutine {
            do {
                let host = try TLSHost(
                    port: port,
                    certificatePath: self.testsPath + "cert.pem",
                    keyPath: self.testsPath + "key.pem"
                )
                
                let stream = try host.accept(deadline: deadline)
                try stream.write("Yo client!", deadline: deadline)
                let read: String = try stream.read(buffer, deadline: deadline)
                XCTAssertEqual(read, "Yo server!")
                try stream.close(deadline: deadline)
                try channel.send(deadline: deadline)
            } catch {
                XCTFail("\(error)")
            }
        }
        
        let stream = try TLSStream(host: "127.0.0.1", port: port, deadline: deadline)
        try stream.open(deadline: deadline)
        let read: String = try stream.read(buffer, deadline: deadline)
        XCTAssertEqual(read, "Yo client!")
        try stream.write("Yo server!", deadline: deadline)
        try stream.close(deadline: deadline)
        try channel.receive(deadline: deadline)
        coroutine.cancel()
    }
}

extension TLSTests {
    public static var allTests: [(String, (TLSTests) -> () throws -> Void)] {
        return [
            ("testConnectionRefused", testConnectionRefused),
            ("testReadWriteClosedSocket", testReadWriteClosedSocket),
            ("testClientServer", testClientServer),
        ]
    }
}
