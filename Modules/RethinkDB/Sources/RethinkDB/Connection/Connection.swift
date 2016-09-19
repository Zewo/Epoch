import Foundation

class Connection {
    fileprivate var queryToken: Int64 = 82

    fileprivate let transport: Transport
    fileprivate let readBuffer: ConnectionReadBuffer
    fileprivate let writeBuffer: ConnectionWriteBuffer

    fileprivate init(transport: Transport) {
        self.transport = transport
        self.readBuffer = ConnectionReadBuffer(transport: transport)
        self.writeBuffer = ConnectionWriteBuffer(transport: transport)
    }

    deinit {
        try? self.transport.close()
    }
}

extension Connection : ConnectionQueryable {
    func run(ast: ReqlAst) throws -> JSON {
        // get token
        let token = self.queryToken
        self.queryToken += 1

        // write query
        try self.writeQuery(token: token, type: .start, query: ast)

        // read response
        var finished: Bool = false
        var results: [JSON] = []
        while !finished {
            let response = try self.readResponse(token: token)



            guard let responseType = ReqlProtocol.ResponseType(rawValue: response["t"]?.int ?? -1) else {
                throw Error(code: .decoding, reason: "Missing or invalid response type.")
            }

            guard let responseResults = response["r"]?.array else {
                throw Error(code: .decoding, reason: "Missing or invalid response results.")
            }

            switch responseType {
            case .successAtom, .successSequence, .serverInfo:
                results += responseResults
                finished = true

            case .successPartial:
                results += responseResults
                try self.writeQuery(token: token, type: .continue)

            case .waitComplete:
                finished = true

            case .clientError, .compileError, .runtimeError:
                let reason = responseResults.first?.string ?? "Unknown Error"
                let backtrace = response["b"]?.string ?? "No Backtrace"
                let type: String
                switch responseType {
                case .clientError:
                    type = "Client"
                case .compileError:
                    type = "Compile"
                case .runtimeError:
                    type = "Runtime"
                default:
                    type = "Unknown"
                }
                throw Error(code: .query(type: type, backtrace: backtrace), reason: reason)
            }
        }

        guard results.count > 1 else {
            return results.first ?? JSON.null
        }
        return JSON.array(results)
    }

    private func writeQuery(token: Int64, type: ReqlProtocol.QueryType, query: ReqlAst? = nil, opts: [String: Any]? = nil) throws {
        var parts: [String] = []

        // prefix
        parts.append("[\(type.rawValue)")

        // query
        if let query = query {
            parts.append(",")
            parts.append(try query.compileToReqlJSON())
        }

        // opts
        if let opts = opts {
            parts.append(",")
            parts.append(try opts.compileToReqlJSON())
        }

        parts.append("]")

        var length: Int = 0
        for part in parts {
            length += part.lengthOfBytes(using: .utf8)
        }

        try self.writeBuffer.write(value: token)
        try self.writeBuffer.write(value: Int32(length))
        for part in parts {
            try self.writeBuffer.write(value: part)
        }

    }

    private func readResponse(token: Int64) throws -> JSON {
        guard try self.readBuffer.read() == token else {
            throw Error(code: .decoding, reason: "Received out of order response.")
        }

        let length: Int32 = try self.readBuffer.read()
        return try self.readBuffer.read(length: Int(length))
    }
}

extension Connection {
    class func connect(config: ReqlConfig) throws -> Connection {
        do {
            let transport = try config.connect()
            let connection = Connection(transport: transport)
            let authenticator = ConnectionAuthenticator(username: config.username, password: config.password)

            // write handshake
            try connection.writeBuffer.write(value: ReqlProtocol.version)

            // write auth challenge request
            try connection.writeBuffer.write(value: try [
                "protocol_version": 0,
                "authentication_method": authenticator.method,
                "authentication": authenticator.clientFirstMessage()
            ].encoded().serialized())
            try connection.writeBuffer.write(bytes: [0])

            // read handeshake response
            let handshakeResponse = try connection.readBuffer.readToNullTerminatedJSON(maxLength: 16384)
            guard handshakeResponse["success"]?.bool == true else {
                let reason = handshakeResponse["error"]?.string ?? "Server rejected handshake."
                throw Error(code: .handshake, reason: reason)
            }


            // read auth challenge request response
            let authChallengeRequestResponse = try connection.readBuffer.readToNullTerminatedJSON(maxLength: 16384)
            guard let authChallenge = authChallengeRequestResponse["authentication"]?.string,
                  authChallengeRequestResponse["success"]?.bool == true else {
                let reason = authChallengeRequestResponse["error"]?.string ?? "Server rejected auth challenge."
                throw Error(code: .authentication, reason: reason)
            }

            // write auth challenge response
            try connection.writeBuffer.write(value: try [
                "authentication": try authenticator.clientFinalMessage(response: authChallenge)
            ].encoded().serialized())
            try connection.writeBuffer.write(bytes: [0])

            // read auth response
            let authResponse = try connection.readBuffer.readToNullTerminatedJSON(maxLength: 16384)
            guard let authProof = authResponse["authentication"]?.string,
                  try authenticator.verifyServerFinalMessage(response: authProof),
                  authResponse["success"]?.bool == true else {
                let reason = authResponse["error"]?.string ?? "Server rejected auth."
                throw Error(code: .authentication, reason: reason)
            }

            return connection
        } catch let error as Error {
            throw error
        } catch {
            throw Error(code: .connection, reason: "Unknown connection error.", underlyingError: error)
        }
    }
}
