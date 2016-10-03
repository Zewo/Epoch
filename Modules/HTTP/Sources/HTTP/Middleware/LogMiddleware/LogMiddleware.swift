import Axis

public struct LogMiddleware : Middleware {
    private let debug: Bool
    private let stream: OutputStream?
    private let timeout: Double

    public init(debug: Bool = false, stream: OutputStream? = nil, timeout: Double = 30.seconds) {
        self.debug = debug
        self.stream = stream
        self.timeout = timeout
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
            try stream.write(message, deadline: timeout.fromNow())
        } else {
            print(message)
        }
        
        return response
    }
}
