@_exported import WebSocket
import Foundation
import HTTP
import HTTPClient

public enum ClientError : Error {
    case unsupportedScheme
    case hostRequired
    case responseNotWebsocket
}

public struct WebSocketClient {
    private let client: Responder
    private let url: URL
    private let didConnect: (WebSocket) throws -> Void
    private let connectionTimeout: Double?
    public init(url: URL, connectionTimeout: Double? = nil, didConnect: @escaping (WebSocket) throws -> Void) throws {
        guard let scheme = url.scheme, scheme == "ws" || scheme == "wss" else {
            throw ClientError.unsupportedScheme
        }
        guard url.host != nil else {
            throw ClientError.hostRequired
        }

        let urlStr = url.absoluteString
        let urlhttp = URL(string: urlStr.replacingCharacters(in: urlStr.range(of:"ws")!, with: "http"))!
        self.client = try HTTPClient.Client(url: urlhttp)
        self.connectionTimeout = connectionTimeout
        self.didConnect = didConnect
        self.url = url
    }

    public init(url: String, connectionTimeout: Double? = nil, didConnect: @escaping (WebSocket) throws -> Void) throws {
        guard let url = URL(string: url) else {
            throw URLError.invalidURL
        }
        try self.init(url: url, connectionTimeout: connectionTimeout, didConnect: didConnect)
    }

    public func connect() throws {
        let key = try Data(bytes: Array(Random.bytes(16))).base64EncodedString(options: [])

        let headers: Headers = [
            "Connection": "Upgrade",
            "Upgrade": "websocket",
            "Sec-WebSocket-Version": "13",
            "Sec-WebSocket-Key": key,
        ]

        var request = Request(method: .get, url: url, headers: headers)

        request.upgradeConnection { response, stream in
            guard response.status == .switchingProtocols && response.isWebSocket else {
                throw ClientError.responseNotWebsocket
            }

            guard let accept = response.webSocketAccept, accept == WebSocket.accept(key) else {
                throw ClientError.responseNotWebsocket
            }
            let webSocket: WebSocket
            if let connectionTimeout = self.connectionTimeout {
                webSocket = WebSocket(stream: stream, mode: .client, connectionTimeout: connectionTimeout)
            } else {
                webSocket = WebSocket(stream: stream, mode: .client)
            }
            try self.didConnect(webSocket)
            try webSocket.start()
        }

        _ = try client.respond(to: request)
    }

    public func connectInBackground(failure: @escaping (Error) -> Void = WebSocketClient.logError) {
        co {
            do {
                try self.connect()
            } catch {
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
        return connection?.lowercased() == "upgrade"
            && upgrade?.lowercased() == "websocket"
    }
}
