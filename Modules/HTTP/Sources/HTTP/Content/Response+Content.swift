import Core

extension Response {
    public var content: Map? {
        get {
            return storage["content"] as? Map
        }

        set(content) {
            storage["content"] = content
        }
    }
}

extension Response {
    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: T, contentType: MediaType? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map

        if let contentType = contentType {
            self.contentType = contentType
        }
    }

    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: T?, contentType: MediaType? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map

        if let contentType = contentType {
            self.contentType = contentType
        }
    }

    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: [T], contentType: MediaType? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map

        if let contentType = contentType {
            self.contentType = contentType
        }
    }

    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: [String: T], contentType: MediaType? = nil) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map

        if let contentType = contentType {
            self.contentType = contentType
        }
    }

    public init<T : MapFallibleRepresentable>(status: Status = .ok, headers: Headers = [:], content: T, contentType: MediaType? = nil) throws {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = try content.asMap()

        if let contentType = contentType {
            self.contentType = contentType
        }
    }
}
