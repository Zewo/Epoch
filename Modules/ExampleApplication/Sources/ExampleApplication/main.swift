import HTTPServer

let arguments = try Configuration.commandLineArguments()
let port = arguments["port"].int ?? 8080
let log = LogMiddleware()

let router = BasicRouter { route in
    route.get("/hello") { request in
        return Response(body: "Hello, world!")
    }
}

let server = try Server(port: port, middleware: [log], responder: router)
try server.start()
