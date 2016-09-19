import XCTest
@testable import Venice
@testable import UDP

public class UDPSocketTests : XCTestCase {
    func testBasicEcho() throws {
        let serverSocket = try UDPSocket(ip: IP(port: 5050))
        let clientSocket = try UDPSocket(ip: IP(port: 5051))

        let originalMessage = "Hello, World!"
        let comparisonChannel = Channel<Bool>()

        // Coroutine waiting for input message
        co {
            var data = Data(count: 1024)
            guard let (count, _) = try? serverSocket.read(into: &data, length: data.count) else {
                return comparisonChannel.send(false)
            }
            // compare the received message and send back the comparison value
            guard let receivedMessage = String(data: Data(data.prefix(count)), encoding: String.Encoding.utf8) else {
                return comparisonChannel.send(false)
            }
            comparisonChannel.send(receivedMessage == originalMessage)
        }

        // Send data to the server
        do {
            try clientSocket.write(Data(originalMessage), to: IP(port: 5050))
        } catch {
            XCTFail("failed to send data to the server")
            return
        }
        // Data was sent to the server

        let success = comparisonChannel.receive()!
        XCTAssert(success, "Sent and received messages are not equal")
    }
}

extension UDPSocketTests {
    public static var allTests: [(String, (UDPSocketTests) -> () throws -> Void)] {
        return [
           ("testBasicEcho", testBasicEcho),
        ]
    }
}
