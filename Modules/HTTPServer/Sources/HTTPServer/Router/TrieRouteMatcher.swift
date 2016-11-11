public struct TrieRouteMatcher {
    private var routesTrie = Trie<String, Route>()
    public let routes: [Route]

    public init(routes: [Route]) {
        self.routes = routes

        for route in routes {
            // insert path components into trie with route being the ending payload
            routesTrie.insert(route.path.pathComponents, payload: route)
        }

        // ensure parameter paths are processed later than static paths
        routesTrie.sort { t1, t2 in
            func rank(_ t: Trie<String, Route>) -> Int {
                if t.prefix == "*" {
                    return 3
                }
                if t.prefix?.unicodeScalars.first == ":" {
                    return 2
                }
                return 1
            }

            return rank(t1) < rank(t2)
        }
    }

    public func match(_ request: Request) -> Route? {
        let components = request.path!.pathComponents
        var parameters: [String: String] = [:]

        let matched = searchForRoute(
            head: routesTrie,
            components: components.makeIterator(),
            parameters: &parameters
        )

        guard let route = matched else {
            return nil
        }

        if parameters.isEmpty {
            return route
        }

        // wrap the route to inject the pathParameters upon receiving a request
        return Route(
            path: route.path,
            middleware: [PathParameterMiddleware(parameters)],
            actions: route.actions,
            fallback: route.fallback
        )
    }

    func searchForRoute(head: Trie<String, Route>, components: IndexingIterator<[String]>, parameters: inout [String: String]) -> Route? {

        var components = components

        // if no more components, we hit the end of the path and
        // may have matched something
        guard let component = components.next() else {
            // if we found something, great! return that
            if let route = head.payload {
                return route
            }
            // last resort: we found nothing, but there _might_ be a wildstar right here
            if let wildstar = head.children.first(where: { child in child.prefix == "*" }) {
                return wildstar.payload
            }
            // nope, got nothing
            return nil
        }

        // store each possible path (ie both a static and a parameter)
        // and then go through them all
        var paths = [(node: Trie<String, Route>, param: String?)]()

        for child in head.children {

            // matched static
            if child.prefix == component {
                paths.append((node: child, param: nil))
                continue
            }

            // matched parameter
            if let prefix = child.prefix, prefix.unicodeScalars.first == ":" {
                let param = String(prefix.unicodeScalars.dropFirst())
                paths.append((node: child, param: param))
                continue
            }

            // matched wildstar
            if child.prefix == "*" {
                paths.append((node: child, param: nil))
                continue
            }
        }

        // go through all the paths and recursively try to match them. if
        // any of them match, the route has been matched
        for (node, param) in paths {

            if let route = node.payload, node.prefix == "*" {
                return route
            }

            let matched = searchForRoute(head: node, components: components, parameters: &parameters)

            // this path matched! we're done
            if let matched = matched {

                // add the parameter if there was one
                if let param = param {
                    parameters[param] = component
                }

                return matched
            }
        }

        // we went through all the possible paths and still found nothing. 404
        return nil
    }
}

extension String {
    fileprivate var pathComponents: [String] {
        let components = unicodeScalars.split(separator: "/").map(String.init)
        return (components.isEmpty ? [""] : components)
    }
}
