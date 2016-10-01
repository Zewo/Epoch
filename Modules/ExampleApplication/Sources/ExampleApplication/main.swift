import HTTPServer

#if os(Linux)
    import Glibc

    public func arc4random_uniform(_ max: UInt32) -> Int32 {
        return (SwiftGlibc.rand() % Int32(max-1)) + 1
    }
#else
    import Darwin
#endif

let contentNegotiation = ContentNegotiationMiddleware(mediaTypes: [.json])

let router = BasicRouter { route in
    route.get("json") { request in
        var json: [String: Int] = [:]

        for i in 1...10 {
            let randomNumber = Int(arc4random_uniform(UInt32(1000)))
            json["Test Number \(i)"] = randomNumber
        }

        return Response(content: json, contentType: .json)
    }
}

try Server(port: 8282, middleware: [contentNegotiation], responder: router).start()
