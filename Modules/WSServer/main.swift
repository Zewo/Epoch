import WebSocketServer
import HTTPServer


do {
let wsServer = WebSocketServer { req, ws in
    print("connected")
    print(req)

        ws.onBinary { data in
        print("data: \(data)")
        try ws.send(data)
      }
      ws.onText { text in
        print("data: \(text)")
        try ws.send(text)
      }
      ws.onPing { data in
        print("data: \(data)")
        try ws.pong()
      }
      ws.onPong { data in
        print("data: \(data)")
        try ws.ping()
      }
      ws.onClose {(code, reason) in
        print("\(code): \(reason)")
      }
}

try HTTPServer.Server(port: 8081, responder: wsServer).start()
} catch {
 print(error)
}

