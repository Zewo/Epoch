
import WebSocketClient
import Venice

var wsock : WebSocket? = nil
var client: WebSocketClient.Client? = nil
var isConnected: Bool = false


func process() {
  do {
  for i in 1...10 {
    print(i)
    if (isConnected) {
        try wsock?.send("hola")
    }
    nap(for:2.seconds)
    if (i % 3 == 0) {
      try wsock?.close(reason: "Shutdown")
    }
  }
  } catch {
    print (error)
  }
}


func connect() {

do {

   client = try WebSocketClient.Client(url:  URL(string: "ws://127.0.0.1:8081")!,
                                                    didConnect: { ws in
                                                      print("WS Connected")
                                                      isConnected = true
                                                      ws.onBinary { data in
                                                        print("data: \(data)")
                                                        // TODO: here log to check why it sent binary data
                                                        try ws.send(data)
                                                      }
                                                      ws.onText { text in
                                                        print("data: \(text)")
                                                        // TODO: process the responses
                                                        //try ws.send(text + "!")
                                                      }
                                                      ws.onPing { (data) in
                                                        try ws.pong()
                                                        print("Ping")
                                                      }
                                                      ws.onPong { (data) in
                                                        try ws.ping()
                                                        print("Pong")
                                                      }
                                                      ws.onClose {(code, reason) in
                                                        isConnected = false
                                                        print("\(code): \(reason)")
                                                      }
                                                      wsock = ws
                                                      // TODO: here seems to be the point where you can send things from
                                                      try ws.send("hi")

                      })
 
  
client!.connectInBackground("ws://127.0.0.1:8081")
  
} catch let error {
  print("Error Occured \(error)")
}

}



  
  connect()


  process()




