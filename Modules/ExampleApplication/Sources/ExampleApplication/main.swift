import HTTPServer

#if os(Linux)
    import SwiftGlibc

    public func arc4random_uniform(_ max: UInt32) -> Int32 {
        return (SwiftGlibc.rand() % Int32(max-1)) + 1
    }
#else
    import Darwin
#endif

func generateJSON() -> [String: Int] {
    var json: [String: Int] = [:]

    for i in 1...10 {
        let randomNumber = Int(arc4random_uniform(UInt32(1000)))
        json["Test Number \(i)"] = randomNumber
    }

    return json
}

let router = BasicRouter { route in
    route.get("json") { request in
        let map = generateJSON().map
        return Response(content: map)
    }
}

try Server(host: "0.0.0.0", port: 8282, responder: router).start()
