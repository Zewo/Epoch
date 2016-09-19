import XCTest
@testable import RethinkDB

extension Socket : Transport {
    public func read(maxBytes: Int) throws -> [UInt8] {
        guard maxBytes > 0 else {
            return []
        }
        var data: Data = Data()
        _ = try self.read(into: &data)
        let bytes = [UInt8](data)
        return bytes
    }

    public func write(bytes: [UInt8]) throws {
        guard bytes.count > 0 else {
            return
        }

        try bytes.withUnsafeBufferPointer { ptr in
            try ptr.baseAddress!.withMemoryRebound(to: Int8.self, capacity: bytes.count) { innerPtr in
                var offset: Int = 0
                var remainingBytes = bytes.count
                while remainingBytes > 0 {
                    let writtenBytes = try self.write(from: innerPtr.advanced(by: offset), bufSize: remainingBytes)
                    offset += writtenBytes
                    remainingBytes -= writtenBytes
                }
            }
        }
    }

}

public class ConnectionTests : XCTestCase {
    private var configured: Bool = false

    override func setUp() {
        if !self.configured {
            r.config = ReqlConfig(connect: { _ throws -> Transport in
                let socket = try Socket.create()
                try socket.connect(to: "localhost", port: 28015)
                return socket
            })
            self.configured = true
        }
        super.setUp()
    }

    func testConnection() {
        let result = try? r.dbList().run()
        print(result)
    }

    func testConnectionToTable() {
        let result = try? r.db("rethinkdb").table("users").filter(["id": "admin"]).run()
        XCTAssertEqual(result["id"]?.string, "admin")
    }

    func testAuthenticatorFauxEmptyPassword() {
        let clientNonce = "nonce"
        let clientFirstMessageEq = "n,,n=admin,r=nonce"
        let serverFirstResponseEq = "r=serverNonce,s=c2VydmVyU2FsdA==,i=1"
        let clientFinalMessageEq = "c=biws,r=serverNonce,p=CaltpKq97KjfxpRAullAl9XTbvVfXbP5x2mYT4xFnlo="

        let authenticator = ConnectionAuthenticator(username: "admin", password: "")

        let clientFirstMessage = authenticator.clientFirstMessage(nonce: clientNonce)
        XCTAssertEqual(clientFirstMessage, clientFirstMessageEq)

        let clientFinalMessage = try? authenticator.clientFinalMessage(response: serverFirstResponseEq)
        XCTAssertEqual(clientFinalMessage, clientFinalMessageEq)
    }

    func testAuthenticatorFauxPassword() {
        let clientNonce = "rOprNGfwEbeRWgbNEkqO"
        let clientFirstMessageEq = "n,,n=user,r=rOprNGfwEbeRWgbNEkqO"
        let serverFirstResponseEq = "r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,s=W22ZaJ0SNY7soEsUEjb6gQ==,i=4096"
        let clientFinalMessageEq = "c=biws,r=rOprNGfwEbeRWgbNEkqO%hvYDpWUa2RaTCAfuxFIlj)hNlF$k0,p=dHzbZapWIk4jUhN+Ute9ytag9zjfMHgsqmmiz7AndVQ="
        let serverLastResponseEq = "v=6rriTRBi23WpRR/wtup+mMhUZUn/dB5nLTJRsjl95G4="

        let authenticator = ConnectionAuthenticator(username: "user", password: "pencil")

        let clientFirstMessage = authenticator.clientFirstMessage(nonce: clientNonce)
        XCTAssertEqual(clientFirstMessage, clientFirstMessageEq)

        let clientFinalMessage = try? authenticator.clientFinalMessage(response: serverFirstResponseEq)
        XCTAssertEqual(clientFinalMessage, clientFinalMessageEq)

        let result = try? authenticator.verifyServerFinalMessage(response: serverLastResponseEq)
        XCTAssertEqual(result, true)
    }
}

extension ConnectionTests {
    public static var allTests: [(String, (ConnectionTests) -> () throws -> Void)] {
        return [
            ("testConnection", testConnection),
            ("testConnectionToTable", testConnectionToTable),
            ("testAuthenticatorFauxEmptyPassword", testAuthenticatorFauxEmptyPassword),
            ("testAuthenticatorFauxPassword", testAuthenticatorFauxPassword),
        ]
    }
}
