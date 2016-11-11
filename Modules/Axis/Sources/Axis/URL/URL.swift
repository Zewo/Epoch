@_exported import struct Foundation.URL
@_exported import struct Foundation.URLQueryItem
import struct Foundation.URLComponents

public enum URLError : Error {
    case invalidURL
}

extension URL {
    public var queryItems: [URLQueryItem] {
#if os(Linux)
        //URLComponents.queryItems crashes on Linux.
        //FIXME: remove that when Foundation will be fixed
        //https://bugs.swift.org/browse/SR-384
        guard let queryPairs = query?.components(separatedBy: "&") else { return [] }
        let items = queryPairs.map { (s) -> URLQueryItem in
            let pair = s.components(separatedBy: "=")
            
            let name = pair[0]
            let value: String? = pair.count > 1 ? pair[1] : nil
            
            return URLQueryItem(name: name, value: value?.removingPercentEncoding)
        }
        
        return items

    
#else
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems ?? []
#endif
    }
}

//extension URI {
//    public var singleValuedQuery: [String: String] {
//        get {
//            var queries: [String: String] = [:]
//
//            let queryTuples = query?.split(separator: "&") ?? []
//
//            for tuple in queryTuples {
//                let queryElements = tuple.split(separator: "=", omittingEmptySubsequences: false)
//                if queryElements.count == 1 {
//                    if let key = try? String(percentEncoded: queryElements[0]) {
//                        queries[key] = ""
//                    }
//                } else if queryElements.count == 2 {
//                    if let
//                        key = try? String(percentEncoded: queryElements[0]),
//                        let value = try? String(percentEncoded: queryElements[1]) {
//                        queries[key] = value
//                    }
//                }
//            }
//
//            return queries
//        }
//
//        set(queryDictionary) {
//            var query = ""
//
//            for (offset: index, element: (key: key, value: value)) in queryDictionary.enumerated() {
//                query += key.percentEncoded(allowing: UTF8.uriQueryAllowed) + "="
//                    + value.percentEncoded(allowing: UTF8.uriQueryAllowed)
//
//                if index < queryDictionary.count - 1 {
//                    query += "&"
//                }
//            }
//
//            self.query = query
//        }
//    }
//
//    public var singleOptionalValuedQuery: [String: String?] {
//        get {
//            var queries: [String: String?] = [:]
//
//            let queryTuples = query?.split(separator: "&") ?? []
//
//            for tuple in queryTuples {
//                let queryElements = tuple.split(separator: "=", omittingEmptySubsequences: false)
//                if queryElements.count == 1 {
//                    if let key = try? String(percentEncoded: queryElements[0]) {
//                        queries[key] = nil as String?
//                    }
//                } else if queryElements.count == 2 {
//                    if let
//                        key = try? String(percentEncoded: queryElements[0]),
//                        let value = try? String(percentEncoded: queryElements[1]) {
//                        queries[key] = value
//                    }
//                }
//            }
//
//            return queries
//        }
//
//        set(queryDictionary) {
//            var query = ""
//
//            for (offset: index, element: (key: key, value: value)) in queryDictionary.enumerated() {
//                if let value = value {
//                    query += key.percentEncoded(allowing: UTF8.uriQueryAllowed) + "="
//                        + value.percentEncoded(allowing: UTF8.uriQueryAllowed)
//                } else {
//                    query += key.percentEncoded(allowing: UTF8.uriQueryAllowed)
//                }
//
//                if index < queryDictionary.count - 1 {
//                    query += "&"
//                }
//            }
//
//            self.query = query
//        }
//    }
//
//    public var multipleValuedQuery: [String: [String]] {
//        get {
//            var queries: [String: [String]] = [:]
//
//            let queryTuples = query?.split(separator: "&") ?? []
//
//            for tuple in queryTuples {
//                let queryElements = tuple.split(separator: "=", omittingEmptySubsequences: false)
//                if queryElements.count == 1 {
//                    if let key = try? String(percentEncoded: queryElements[0]) {
//                        let values = queries[key] ?? []
//                        queries[key] = values + [""]
//                    }
//                } else if queryElements.count == 2 {
//                    if let key = try? String(percentEncoded: queryElements[0]),
//                        let value = try? String(percentEncoded: queryElements[1]) {
//                        let values = queries[key] ?? []
//                        queries[key] = values + [value]
//                    }
//                }
//            }
//
//            return queries
//        }
//
//        set(queryDictionary) {
//            var query = ""
//
//            for (offset: index, element: (key: key, value: values)) in queryDictionary.enumerated() {
//                for (index, value) in values.enumerated() {
//                    query += key.percentEncoded(allowing: UTF8.uriQueryAllowed) + "="
//                        + value.percentEncoded(allowing: UTF8.uriQueryAllowed)
//
//                    if index < values.count - 1 {
//                        query += "&"
//                    }
//                }
//
//                if index < queryDictionary.count - 1 {
//                    query += "&"
//                }
//            }
//
//            self.query = query
//        }
//    }
//
//    public var multipleOptionalValuedQuery: [String: [String?]] {
//        get {
//            var queries: [String: [String?]] = [:]
//
//            let queryTuples = query?.split(separator: "&") ?? []
//
//            for tuple in queryTuples {
//                let queryElements = tuple.split(separator: "=", omittingEmptySubsequences: false)
//                if queryElements.count == 1 {
//                    if let key = try? String(percentEncoded: queryElements[0]) {
//                        let values = queries[key] ?? []
//                        queries[key] = values + [nil]
//                    }
//                } else if queryElements.count == 2 {
//                    if let key = try? String(percentEncoded: queryElements[0]),
//                        let value = try? String(percentEncoded: queryElements[1]) {
//                        let values = queries[key] ?? []
//                        queries[key] = values + ([value] as [String?])
//                    }
//                }
//            }
//
//            return queries
//        }
//
//        set(queryDictionary) {
//            var query = ""
//
//            for (offset: index, element: (key: key, value: values)) in queryDictionary.enumerated() {
//                for (index, value) in values.enumerated() {
//                    if let value = value {
//                        query += key.percentEncoded(allowing: UTF8.uriQueryAllowed) + "="
//                            + value.percentEncoded(allowing: UTF8.uriQueryAllowed)
//                    } else {
//                        query += key.percentEncoded(allowing: UTF8.uriQueryAllowed)
//                    }
//
//                    if index < values.count - 1 {
//                        query += "&"
//                    }
//                }
//
//                if index < queryDictionary.count - 1 {
//                    query += "&"
//                }
//            }
//
//            self.query = query
//        }
//    }
//}
//
//extension URI {
//    public func percentEncoded() -> String {
//        var string = ""
//
//        if let scheme = scheme {
//            string += scheme + "://"
//        }
//
//        if let userInfo = userInfo?.percentEncoded() {
//            string += userInfo + "@"
//        }
//
//        if let host = host?.percentEncoded(allowing: UTF8.uriHostAllowed) {
//            string += host
//        }
//
//        if let port = port {
//            string += ":" + String(port)
//        }
//
//        if let path = path?.percentEncoded(allowing: UTF8.uriQueryAllowed) {
//            string += path
//        }
//
//        if let query = query {
//            string += "?" + query
//        }
//
//        if let fragment = fragment?.percentEncoded(allowing: UTF8.uriFragmentAllowed) {
//            string += "#" + fragment
//        }
//
//        return string
//    }
//}
