@_exported import WebSocket
import Foundation

import HTTP
import HTTPClient

public enum ClientError: Error {
    case unsupportedScheme
    case hostRequired
    case responseNotWebsocket
}

public struct Client {
    private let client: Responder
    private let didConnect: (WebSocket) throws -> Void

    public init(url: URL, didConnect: @escaping (WebSocket) throws -> Void) throws {
        guard let scheme = url.scheme , scheme == "ws" || scheme == "wss" else {
            throw ClientError.unsupportedScheme
        }

        guard let _ = url.host else {
            throw ClientError.hostRequired
        }
        let urlStr = url.absoluteString
        let urlhttp = URL(string: urlStr.replacingCharacters(in: urlStr.range(of:"ws")!, with: "http"))!
        self.client = try HTTPClient.Client(url: urlhttp)

        self.didConnect = didConnect
    }

    public func connect(_ path: String) throws {
        let a = try Random.bytes(16).filter {_ in return true}

        let key = Data(bytes: a).base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))

        let headers: Headers = [
            "Connection": "Upgrade",
            "Upgrade": "websocket",
            "Sec-WebSocket-Version": "13",
            "Sec-WebSocket-Key": key,
        ]

        var request = Request(method: .get, url: path, headers: headers)
        request?.upgradeConnection { response, stream in
            guard response.status == .switchingProtocols && response.isWebSocket else {
                throw ClientError.responseNotWebsocket
            }

            guard let accept = response.webSocketAccept , accept == WebSocket.accept(key) else {
                throw ClientError.responseNotWebsocket
            }

            let webSocket = WebSocket(stream: stream, mode: .client)
            try self.didConnect(webSocket)
            try webSocket.start()
        }

        _ = try client.respond(to: request!)
    }

    public func connectInBackground(_ path: String, failure: @escaping (Error) -> Void = Client.logError) {
        co {
            do {
                try self.connect(path)
            } catch {
                print ("toto")
                failure(error)
            }
        }
    }

    static func logError(error: Error) {
        print(error)
    }
}

public extension Response {
    public var webSocketVersion: String? {
        return headers["Sec-Websocket-Version"]
    }

    public var webSocketKey: String? {
        return headers["Sec-Websocket-Key"]
    }

    public var webSocketAccept: String? {
        return headers["Sec-WebSocket-Accept"]
    }

    public var isWebSocket: Bool {
        return connection?.lowercased() == "upgrade" && upgrade?.lowercased() == "websocket"
    }
}
