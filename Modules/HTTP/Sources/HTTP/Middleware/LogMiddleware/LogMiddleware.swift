import Core


public struct LogMiddleware : Middleware {
    private let debug: Bool
    private let stream: OutputStream?

    public init(debug: Bool = false, stream: OutputStream? = nil) {
        self.debug = debug
        self.stream = stream
    }
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        let response = try next.respond(to: request)
        var message: String = ""
        message = "================================================================================\n"
        message += "Request:\n\n"
        message += (debug ? String(describing: request.debugDescription) : String(describing: request)) + "\n"
        message += "--------------------------------------------------------------------------------\n"
        message += "Response:\n\n"
        message += (debug ? String(describing: response.debugDescription) : String(describing: response)) + "\n"
        message += "================================================================================\n"
        if let stream = stream {
            try stream.write(message)
        } else {
            print(message)
        }
        return response
    }
}
