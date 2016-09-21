import Foundation

extension Request {
    public var content: Map? {
        get {
            return storage["content"] as? Map
        }

        set(content) {
            storage["content"] = content
        }
    }
}

extension Request {
    public init<T : MapRepresentable>(method: Method = .get, url: URL = URL(string: "/")!, headers: Headers = [:], content: T) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T: MapRepresentable>(method: Method = .get, url: URL = URL(string: "/")!, headers: Headers = [:], content: T?) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T: MapRepresentable>(method: Method = .get, url: URL = URL(string: "/")!, headers: Headers = [:], content: [T]) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T: MapRepresentable>(method: Method = .get, url: URL = URL(string: "/")!, headers: Headers = [:], content: [String: T]) {
        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T : MapFallibleRepresentable>(method: Method = .get, url: URL = URL(string: "/")!, headers: Headers = [:], content: T) throws {
        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = try content.asMap()
    }
}

extension Request {
    public init?<T : MapRepresentable>(method: Method = .get, url: String, headers: Headers = [:], content: T) {
        guard let url = URL(string: url) else {
            return nil
        }

        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init?<T: MapRepresentable>(method: Method = .get, url: String, headers: Headers = [:], content: T?) {
        guard let url = URL(string: url) else {
            return nil
        }

        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init?<T: MapRepresentable>(method: Method = .get, url: String, headers: Headers = [:], content: [T]) {
        guard let url = URL(string: url) else {
            return nil
        }

        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init?<T: MapRepresentable>(method: Method = .get, url: String, headers: Headers = [:], content: [String: T]) {
        guard let url = URL(string: url) else {
            return nil
        }

        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = content.map
    }

    public init<T : MapFallibleRepresentable>(method: Method = .get, url: String, headers: Headers = [:], content: T) throws {
        guard let url = URL(string: url) else {
            throw URLError.invalidURL
        }

        self.init(
            method: method,
            url: url,
            headers: headers,
            body: Buffer()
        )

        self.content = try content.asMap()
    }
}
