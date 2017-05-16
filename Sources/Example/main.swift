import HTTP

let router = BasicRouter { root in
    root.get { request in
        return Response(status: .ok, body: "hello world", timeout: 5.seconds)
    }
}

let server = Server(router: router)
try server.start()
