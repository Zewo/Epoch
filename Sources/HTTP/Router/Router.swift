import Core

public enum RouterError : Error {
    case notFound
    case methodNotAllowed
}

extension RouterError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case .notFound:
            return Response(status: .notFound)
        case .methodNotAllowed:
            return Response(status: .methodNotAllowed)
        }
    }
}

open class BasicRouter {
    fileprivate struct Path {
        private var path: String.CharacterView
        
        fileprivate init(_ path: String) {
            self.path = path.characters.dropFirst()
        }
        
        fileprivate mutating func popPathComponent() -> String? {
            if path.isEmpty {
                return nil
            }
            
            var pathComponent = String.CharacterView()
            
            while let character = path.popFirst() {
                guard character != "/" else {
                    break
                }
                
                pathComponent.append(character)
            }
            
            return String(pathComponent)
        }
    }
    
    public typealias Respond = (Request) throws -> Response
    
    fileprivate var subrouters: [String: BasicRouter] = [:]
    fileprivate var responders: [Method: Respond] = [:]
    
    init() {}
    
    public convenience init(_ body: (BasicRouter) -> Void) {
        self.init()
        body(self)
    }
    
    public func add(path: String, body: (BasicRouter) -> Void) {
        let route = BasicRouter()
        body(route)
        return subrouters[path] = route
    }
    
    public func respond(method: Method, body: @escaping Respond) {
        responders[method] = body
    }
    
    public func get(body: @escaping Respond) {
        respond(method: .get, body: body)
    }
    
    public func post(body: @escaping Respond) {
        respond(method: .post, body: body)
    }
    
    public func put(body: @escaping Respond) {
        respond(method: .put, body: body)
    }
    
    public func patch(body: @escaping Respond) {
        respond(method: .patch, body: body)
    }
    
    public func delete(body: @escaping Respond) {
        respond(method: .delete, body: body)
    }
    
    public func respond(to request: Request) -> Response {
        do {
            var path = Path(request.uri.path ?? "/")
            return try respond(to: request, path: &path)
        } catch {
            return recover(from: error)
        }
    }
    
    @inline(__always)
    private func respond(to request: Request, path: inout Path) throws -> Response {
        if let pathComponent = path.popPathComponent() {
            guard let subrouter = subrouters[pathComponent] else {
                throw RouterError.notFound
            }
            
            return try subrouter.respond(to: request, path: &path)
        }
        
        if let respond = responders[request.method] {
            return try respond(request)
        }
        
        throw RouterError.methodNotAllowed
    }
    
    @inline(__always)
    private func recover(from error: Error) -> Response {
        switch error {
        case let error as ResponseRepresentable:
            return error.response
        default:
            return Response(status: .internalServerError)
        }
    }
}
