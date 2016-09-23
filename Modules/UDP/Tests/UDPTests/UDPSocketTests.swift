import XCTest
@testable import Venice
@testable import UDP
import struct Foundation.Data

public class UDPSocketTests : XCTestCase {
    
    func testBasicClientServer() throws {
        let serverSocket = try UDPSocket(ip: IP(port: 5050))
        let clientSocket = try UDPSocket(ip: IP(port: 5051)).sending(to: IP(port: 5050))

        let originalMessage = "Hello, World!"
        let doneChannel = Channel<Void>()

        // Coroutine for the server socket
        co {
            do {
                let buffer = try Buffer(capacity: 1024) {
                    try serverSocket.read(into: $0)
                }
                
                // Check received buffer has appropriate count and content
                XCTAssertEqual(buffer.count, originalMessage.characters.count)
                XCTAssertEqual(buffer, Buffer(originalMessage))
                
                // Not mandatory: compare received and original string messages
                let receivedMessage = try String(buffer: buffer)
                XCTAssertEqual(receivedMessage, originalMessage)
                
            } catch {
                XCTFail()
            }
            
            doneChannel.send()
        }
        

        // Send data to the server
        do {
            try clientSocket.write(Buffer(originalMessage))
        } catch {
            XCTFail("failed to send data to the server")
            return
        }
        
        doneChannel.receive()!
    }
    
    
    /// Sending *to* a closed UDP port should *not* fail: this is UDP
    func testSendToClosedSocket() throws {
        let clientSocket = try UDPSocket(ip: IP(port: 5051)).sending(to: IP(port: 5052))
        try clientSocket.write(Buffer([1, 2, 3]))
        XCTAssert(true, "Could not write to UDPSocket")
    }
    
    
    /// Sending *from* a closed UDP port should fail
    func testSendFromClosedSocket() throws {
        let clientSocket = try UDPSocket(ip: IP(port: 5051)).sending(to: IP(port: 5052))
        clientSocket.close()
        XCTAssertThrowsError(try clientSocket.write(Buffer([1, 2, 3])))
    }
    
}

extension UDPSocketTests {
    public static var allTests: [(String, (UDPSocketTests) -> () throws -> Void)] {
        return [
           ("testBasicEcho", testBasicClientServer),
           ("testSendToClosedSocket", testSendToClosedSocket),
           ("testSendFromClosedSocket", testSendFromClosedSocket),
        ]
    }
}
