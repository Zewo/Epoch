import Foundation

class ConnectionAuthenticator {
    let username: String
    let password: String
    let method: String = "SCRAM-SHA-256"

    private var nonce: String = ""
    private var clientProof: String = ""
    private var serverProof: String = ""

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    func clientFirstMessage(nonce: String? = nil) -> String {
        self.nonce = nonce ?? Data(bytes: [UInt8](UUID().uuidString.utf8)).base64EncodedString()
        return "n,,n=\(self.username),r=\(self.nonce)"
    }

    func clientFinalMessage(response: String) throws -> String {
        let pairs = self.pairsFrom(response: response)
        guard let combinedNonce = pairs["r"],
              let salt = pairs["s"],
              let iterations = Int(pairs["i"] ?? ""),
              let saltData = Data(base64Encoded: salt) else {
                throw Error(code: .authentication, reason: "Could not parse authentication challenge.")
        }

        guard let passwordData = self.password.data(using: .utf8) else {
            throw Error(code: .authentication, reason: "Could not form authentication challenge response.")
        }

        let passwordBytes: [UInt8] = passwordData.withUnsafeBytes { [UInt8](UnsafeBufferPointer(start: $0, count: passwordData.count)) }
        let saltBytes: [UInt8] = saltData.withUnsafeBytes { [UInt8](UnsafeBufferPointer(start: $0, count: saltData.count)) }

        let passwordKeyBytes: [UInt8]
        if iterations > 1 || passwordBytes.count > 0 {
            passwordKeyBytes = try PKCS5.PBKDF2(password: passwordBytes, salt: saltBytes, iterations: iterations, keyLength: nil, variant: .sha256).calculate()
        } else {
            // SHOULD BE: <b9008f37 524da237 3b897e51 d4d01430 377cfe4f 68724a6b 1d0823c3 7a09bafb>
            // HAVE:      <b9008f37 524da237 3b897e51 d4d01430 377cfe4f 68724a6b 1d0823c3 7a09bafb>
            passwordKeyBytes = try HMAC(key: passwordBytes, variant: .sha256).authenticate(saltBytes + [0x00, 0x00, 0x00, 0x01])
        }
        let clientKeyBytes = try HMAC(key: passwordKeyBytes, variant: .sha256).authenticate([UInt8]("Client Key".utf8))
        let serverKeyBytes = try HMAC(key: passwordKeyBytes, variant: .sha256).authenticate([UInt8]("Server Key".utf8))
        let storedKeyBytes = Digest.sha256(clientKeyBytes)

        let authBytes = [UInt8]("n=\(self.username),r=\(self.nonce),\(response),c=biws,r=\(combinedNonce)".utf8)
        let clientSignatureBytes = try HMAC(key: storedKeyBytes, variant: .sha256).authenticate(authBytes)
        let serverProofBytes = try HMAC(key: serverKeyBytes, variant: .sha256).authenticate(authBytes)
        let clientProofBytes = xor(value: clientKeyBytes, key: clientSignatureBytes)

        self.clientProof = Data(bytes: clientProofBytes).base64EncodedString()
        self.serverProof = Data(bytes: serverProofBytes).base64EncodedString()

        return "c=biws,r=\(combinedNonce),p=\(self.clientProof)"

    }

    func verifyServerFinalMessage(response: String) throws -> Bool {
        guard "v=\(self.serverProof)" == response else {
            throw Error(code: .authentication, reason: "Could not validate server proof.")
        }
        return true
    }

    private func xor(value: [UInt8], key: [UInt8]) -> [UInt8] {
        var result = value
        var y = 0
        for x in 0..<result.count {
            result[x] = result[x] ^ key[y]
            y += 1
            if y == key.count {
                y = 0
            }
        }
        return result
    }

    private func pairsFrom(response: String) -> [String: String] {
        var pairs: [String: String] = [:]
        for part in response.characters.split(separator: ",") where String(part).characters.count >= 3 {
            let part = String(part)
            if let first = part.characters.first {
                let data = part[part.index(part.startIndex, offsetBy: 2)..<part.endIndex]
                pairs[String(first)] = data
            }
        }
        return pairs
    }
}
