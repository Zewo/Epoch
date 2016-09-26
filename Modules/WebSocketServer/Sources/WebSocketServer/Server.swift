// Server.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import WebSocket
@_exported import HTTP

public struct WebSocketServer: Responder, Middleware {
    private let didConnect: (Request, WebSocket) throws -> Void

    public init(_ didConnect: @escaping (Request, WebSocket) throws -> Void) {
        self.didConnect = didConnect
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        guard request.isWebSocket && request.webSocketVersion == "13", let key = request.webSocketKey else {
            return try next.respond(to: request)
        }

        guard let accept = WebSocket.accept(key) else {
            return Response(status: .internalServerError)
        }

        let headers: Headers = [
            "Connection": "Upgrade",
            "Upgrade": "websocket",
            "Sec-WebSocket-Accept": accept
        ]

        var response = Response(status: .switchingProtocols, headers: headers)
        response.upgradeConnection { request, stream in
            let webSocket = WebSocket(stream: stream, mode: .server)
            try self.didConnect(request, webSocket)
            try webSocket.start()
        }

        return response
    }

    public func respond(to request: Request) throws -> Response {
        let badRequest = BasicResponder { _ in
          throw ClientError.badRequest(headers: request.headers, body: request.body)
        }

        return try respond(to: request, chainingTo: badRequest)
    }
}

public extension Request {
    public func webSocket(didConnect: @escaping (Request, WebSocket) -> ()) throws -> Response {
        return try WebSocketServer(didConnect).respond(to: self)
    }
}

public extension Request {
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
