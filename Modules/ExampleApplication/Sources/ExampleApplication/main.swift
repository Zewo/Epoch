import HTTPServer
import HTTPClient

// fetches port to serve on from command line arguments
let arguments = try Configuration.commandLineArguments()
let port = arguments["port"].int ?? 8080

// logs all incoming requests and responses
let log = LogMiddleware()
// catches errors and formats them if possible
let recover = RecoveryMiddleware()
let session = SessionMiddleware()

// sends requests to different handlers based on their path
let router = BasicRouter { route in

    route.get("/dash") { request in
        guard try request.session["loggedIn"].get() ?? false else {
            return Response(body: "<html><head></head><body>Not logged in. <a href='/login'>login</login></body></html>")
        }
        return Response(body: "Hello!")
    }

    route.get("/login") { request in
        //TODO: is there anyting we can do about this? request.rawSession.storage mutation 
        var request = request
        if try request.session["loggedIn"].get() ?? false {
            return Response(body: "Already logged in")
        }
        request.session["loggedIn"] = true
        return Response(body: "Now logged in!")
    }

    // reponds to GET /hello with hello world
    route.get("/hello") { request in
        return Response(body: "Hello, world!")
    }

    // forwards all requests to github api
    // for example, GET /orgs/zewo hits api.github.com/orgs/zewo
    route.get("/orgs/*") { request in
        let client = try Client(url: "https://api.github.com")
        return try client.get(request.path ?? "")
    }
}

// ties everything together
let server = try Server(port: port, middleware: [log, recover, session], responder: router)

// starts the actual server
try server.start()
