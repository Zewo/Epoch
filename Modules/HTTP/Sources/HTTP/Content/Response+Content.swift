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
    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: T) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: T?) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: [T]) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T : MapRepresentable>(status: Status = .ok, headers: Headers = [:], content: [String: T]) {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T : MapFallibleRepresentable>(status: Status = .ok, headers: Headers = [:], content: T) throws {
        self.init(
            status: status,
            headers: headers,
            body: Buffer()
        )

        self.content = try content.asMap()
    }
}
