import HTTPServer
import HTTPClient

let router = BasicRouter { route in
    route.get("/old-file") { request in
        let file = try FileDescriptorStream(path: "/Users/paulofaria/Desktop/book.pdf")
        return Response(body: file)
    }

    route.get("/new-file") { request in
        let file = try File(path: "/Users/paulofaria/Desktop/book.pdf")
        return Response(body: file)
    }

    route.get("/newer-file") { request in
        return Response(filePath: "/Users/paulofaria/Desktop/book.pdf")
    }

    route.get("/orgs/*") { request in
        let client = try Client(url: "https://api.github.com")
        return try client.get(request.path ?? "")
    }
}

let server = try Server(port: 8383, bufferSize: Int(2E6), responder: router)
try server.start()

