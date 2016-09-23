public class ResponseSerializer {
    let stream: Stream
    let bufferSize: Int

    public init(stream: Stream, bufferSize: Int = 2048) {
        self.stream = stream
        self.bufferSize = bufferSize
    }

    public func serialize(_ response: Response) throws {
        let newLine: [UInt8] = [13, 10]

        try stream.write("HTTP/\(response.version.major).\(response.version.minor) \(response.status.statusCode) \(response.status.reasonPhrase)")
        try stream.write(newLine)

        for (name, value) in response.headers.headers {
            try stream.write("\(name): \(value)")
            try stream.write(newLine)
        }

        for cookie in response.cookieHeaders {
            try stream.write("Set-Cookie: \(cookie)")
            try stream.write(newLine)
        }

        try stream.write(newLine)

        switch response.body {
        case .buffer(let buffer):
            try stream.write(buffer)
        case .reader(let reader):
            while !reader.closed {
                let buffer = try reader.read(upTo: bufferSize)
                guard !buffer.isEmpty else {
                    break
                }

                try stream.write(String(buffer.count, radix: 16))
                try stream.write(newLine)
                try stream.write(buffer)
                try stream.write(newLine)
            }

            try stream.write("0")
            try stream.write(newLine)
            try stream.write(newLine)
        case .writer(let writer):
            let body = BodyStream(stream)
            try writer(body)

            try stream.write("0")
            try stream.write(newLine)
            try stream.write(newLine)
        }

        try stream.flush()
    }
}
