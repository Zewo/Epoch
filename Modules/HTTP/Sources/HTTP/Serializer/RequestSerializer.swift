public class RequestSerializer {
    let stream: Stream
    let bufferSize: Int

    public init(stream: Stream, bufferSize: Int = 2048) {
        self.stream = stream
        self.bufferSize = bufferSize
    }

    public func serialize(_ request: Request, deadline: Double) throws {
        let newLine: [UInt8] = [13, 10]

        try stream.write("\(request.method) \(request.url.absoluteString) HTTP/\(request.version.major).\(request.version.minor)", deadline: deadline)
        try stream.write(newLine, deadline: deadline)

        for (name, value) in request.headers.headers {
            try stream.write("\(name): \(value)", deadline: deadline)
            try stream.write(newLine, deadline: deadline)
        }

        try stream.write(newLine, deadline: deadline)

        switch request.body {
        case .buffer(let buffer):
            try stream.write(buffer, deadline: deadline)
        case .reader(let reader):
            while !reader.closed {
                let buffer = try reader.read(upTo: bufferSize, deadline: deadline)
                guard !buffer.isEmpty else {
                    break
                }

                try stream.write(String(buffer.count, radix: 16), deadline: deadline)
                try stream.write(newLine, deadline: deadline)
                try stream.write(buffer, deadline: deadline)
                try stream.write(newLine, deadline: deadline)
            }

            try stream.write("0", deadline: deadline)
            try stream.write(newLine, deadline: deadline)
            try stream.write(newLine, deadline: deadline)
        case .writer(let writer):
            let body = BodyStream(stream)
            try writer(body)

            try stream.write("0", deadline: deadline)
            try stream.write(newLine, deadline: deadline)
            try stream.write(newLine, deadline: deadline)
        case .file(let filePath):
            try stream.write(filePath: filePath, deadline: deadline)
        }

        try stream.flush(deadline: deadline)
    }
}
