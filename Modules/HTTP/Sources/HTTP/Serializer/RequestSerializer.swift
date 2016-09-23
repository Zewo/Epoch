public class RequestSerializer {
    let stream: Stream
    let bufferSize: Int

    public init(stream: Stream, bufferSize: Int = 2048) {
        self.stream = stream
        self.bufferSize = bufferSize
    }

    public func serialize(_ request: Request) throws {
        let newLine: [UInt8] = [13, 10]

        try stream.write("\(request.method) \(request.url.absoluteString) HTTP/\(request.version.major).\(request.version.minor)")
        try stream.write(newLine)

        for (name, value) in request.headers.headers {
            try stream.write("\(name): \(value)")
            try stream.write(newLine)
        }

        try stream.write(newLine)

        switch request.body {
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
