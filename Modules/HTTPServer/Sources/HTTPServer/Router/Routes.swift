open class Routes {
    public let staticFilesPath: String
    public var routes: [Route] = []

    public lazy var fallback: Responder = FileResponder(path: self.staticFilesPath)

    public init(staticFilesPath: String) {
        self.staticFilesPath = staticFilesPath
    }
}

extension Routes {
    public func compose(_ path: String, middleware: [Middleware] = [], router representable: RouterRepresentable) {
        let router = representable.router
        let middleware = middleware + router.middleware
        for route in router.routes {
            for (method, responder) in route.actions {
                add(method: method, path: path + route.path, middleware: middleware, responder: responder)
            }
        }
    }
}

extension Routes {
    public func fallback(middleware: [Middleware] = [], respond: @escaping Respond) {
        fallback(middleware: middleware, responder: BasicResponder(respond))
    }

    public func fallback(middleware: [Middleware] = [], responder: Responder) {
        fallback = middleware.chain(to: responder)
    }
}

extension Routes {
    public func get(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        get(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func get(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .get, path: path, middleware: middleware, responder: responder)
    }

    public func get<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        T: MapInitializable
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }

    public func get<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .get, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func head(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        head(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func head(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .head, path: path, middleware: middleware, responder: responder)
    }

    public func head<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        T: MapInitializable
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }

    public func head<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .head, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func post(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        post(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func post(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .post, path: path, middleware: middleware, responder: responder)
    }

    public func post<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        T: MapInitializable
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }

    public func post<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .post, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func put(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        put(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func put(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .put, path: path, middleware: middleware, responder: responder)
    }

    public func put<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        T: MapInitializable
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }

    public func put<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .put, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func patch(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        patch(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func patch(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .patch, path: path, middleware: middleware, responder: responder)
    }

    public func patch<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        T: MapInitializable
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }

    public func patch<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .patch, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func delete(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        delete(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func delete(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .delete, path: path, middleware: middleware, responder: responder)
    }

    public func delete<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        T: MapInitializable
        >(
        _ path: String = "",
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }

    public func delete<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .delete, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func options(
        _ path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping Respond) {
        options(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func options(
        _ path: String = "",
        middleware: [Middleware] = [],
        responder: Responder) {
        add(method: .options, path: path, middleware: middleware, responder: responder)
    }

    public func options<
        A: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        _ path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, T) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, T) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, T) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }

    public func options<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        _ path: String,
        middleware: [Middleware] = [],
        content: T.Type = T.self,
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        add(method: .options, path: path, middleware: middleware, respond: respond)
    }
}

extension Routes {
    public func add(methods: Set<Request.Method>, path: String = "", middleware: [Middleware] = [], responder: Responder) {
        for method in methods {
            add(method: method, path: path, middleware: middleware, responder: responder)
        }
    }

    public func add(methods: Set<Request.Method>, path: String = "", middleware: [Middleware] = [], respond: @escaping Respond) {
        add(methods: methods, path: path, middleware: middleware, responder: BasicResponder(respond))
    }
}

extension Routes {
    public func add<
        A: PathParameterConvertible
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 1)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])

            return try respond(request, a)
        }

        add(method: method, path: path, middleware: middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        B: PathParameterConvertible
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 2)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])
            let b = try B(pathParameter: parameters[1])

            return try respond(request, a, b)
        }

        add(method: method, path: path, middleware: middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 3)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])
            let b = try B(pathParameter: parameters[1])
            let c = try C(pathParameter: parameters[2])

            return try respond(request, a, b, c)
        }

        add(method: method, path: path, middleware: middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 4)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])
            let b = try B(pathParameter: parameters[1])
            let c = try C(pathParameter: parameters[2])
            let d = try D(pathParameter: parameters[3])

            return try respond(request, a, b, c, d)
        }

        add(method: method, path: path, middleware: middleware, responder: responder)
    }

    public func add<
        T: MapInitializable
        >(
        method: Request.Method,
        path: String = "",
        middleware: [Middleware] = [],
        respond: @escaping (_ request: Request, _ content: T) throws -> Response) {
        let contentMapper = ContentMapperMiddleware(mappingTo: T.self)
        let responder = BasicResponder { request in
            guard let content = request.storage[T.contentMapperKey] as? T else {
                throw HTTPError.badRequest
            }
            return try respond(request, content)
        }
        add(method: method, path: path, middleware: [contentMapper] + middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        T: MapInitializable
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, T) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 1)
        let contentMapper = ContentMapperMiddleware(mappingTo: T.self)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])

            guard let content = request.storage[T.contentMapperKey] as? T else {
                throw HTTPError.badRequest
            }

            return try respond(request, a, content)
        }

        add(method: method, path: path, middleware: [contentMapper] + middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        T: MapInitializable
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, T) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 2)
        let contentMapper = ContentMapperMiddleware(mappingTo: T.self)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])
            let b = try B(pathParameter: parameters[1])
            guard let content = request.storage[T.contentMapperKey] as? T else {
                throw HTTPError.badRequest
            }

            return try respond(request, a, b, content)
        }

        add(method: method, path: path, middleware: [contentMapper] + middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        T: MapInitializable
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, T) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 3)
        let contentMapper = ContentMapperMiddleware(mappingTo: T.self)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])
            let b = try B(pathParameter: parameters[1])
            let c = try C(pathParameter: parameters[2])

            guard let content = request.storage[T.contentMapperKey] as? T else {
                throw HTTPError.badRequest
            }

            return try respond(request, a, b, c, content)
        }

        add(method: method, path: path, middleware: [contentMapper] + middleware, responder: responder)
    }

    public func add<
        A: PathParameterConvertible,
        B: PathParameterConvertible,
        C: PathParameterConvertible,
        D: PathParameterConvertible,
        T: MapInitializable
        >(
        method: Request.Method,
        path: String,
        middleware: [Middleware] = [],
        respond: @escaping (Request, A, B, C, D, T) throws -> Response) {
        let keys = parseParameterKeys(path: path, count: 4)
        let contentMapper = ContentMapperMiddleware(mappingTo: T.self)
        let responder = BasicResponder { request in
            let parameters = try self.parseParameters(
                keys: keys,
                pathParameters: request.pathParameters
            )

            let a = try A(pathParameter: parameters[0])
            let b = try B(pathParameter: parameters[1])
            let c = try C(pathParameter: parameters[2])
            let d = try D(pathParameter: parameters[3])

            guard let content = request.storage[T.contentMapperKey] as? T else {
                throw HTTPError.badRequest
            }

            return try respond(request, a, b, c, d, content)
        }

        add(method: method, path: path, middleware: [contentMapper] + middleware, responder: responder)
    }

    private func parseParameters(keys: [String], pathParameters: [String: String]) throws -> [String] {
        guard keys.count == pathParameters.count else {
            throw HTTPError.internalServerError
        }

        return keys.flatMap({ pathParameters[$0] })
    }

    // Todo: if there are repeated identifiers call malformedRoute
    private func parseParameterKeys(path: String, count: Int) -> [String] {
        let split = path.characters
            .split(separator: "/")
            .map(String.init)
        let keys = split
            .map({ $0.characters })
            .filter({ $0.first == ":" })
            .map({ $0.dropFirst() })
            .map({ String($0) })

        if keys.count != count {
            fatalError("Invalid route \"\(path)\". The number of path parameters doesn't match the number of strong typed parameters in the route.")
        }

        if Set(keys).count != count {
            fatalError("Invalid route \"\(path)\". Path parameter names should be distinct.")
        }

        return keys
    }
}

extension Routes {
    public func fallback(_ path: String, middleware: [Middleware] = [], respond: @escaping Respond) {
        fallback(path, middleware: middleware, responder: BasicResponder(respond))
    }

    public func add(method: Request.Method, path: String = "", middleware: [Middleware] = [], respond: @escaping Respond) {
        add(method: method, path: path, middleware: middleware, responder: BasicResponder(respond))
    }
}

extension Routes {
    public func fallback(_ path: String, middleware: [Middleware] = [], responder: Responder) {
        let fallback = middleware.chain(to: responder)
        let routePath = path

        if let route = route(for: routePath) {
            route.fallback = fallback
        } else {
            let route = Route(path: routePath, fallback: fallback)
            routes.append(route)
        }
    }
    
    public func add(method: Request.Method, path: String = "", middleware: [Middleware] = [], responder: Responder) {
        let action = middleware.chain(to: responder)
        let routePath = path
        
        if let route = route(for: routePath) {
            route.addAction(method: method, action: action)
        } else {
            let route = Route(path: routePath, actions: [method: action], fallback: self.fallback)
            routes.append(route)
        }
    }
    
    private func route(for path: String) -> Route? {
        for route in routes where route.path == path {
            return route
        }
        return nil
    }
}
