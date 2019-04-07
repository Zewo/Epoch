import Core
import Media
import Venice

// TODO: Make error CustomStringConvertible and ResponseRepresentable
public enum MessageError : Error {
    case noReadableBody
    case noContentTypeHeader
    case unsupportedMediaType
    case noDefaultContentType
    case notContentRepresentable
    case valueNotFound(key: String)
    case incompatibleType(requestedType: Any.Type, actualType: Any.Type)
}

public typealias Storage = [String: Any]

public protocol Message : class {
    var version: Version { get set }
    var headers: Headers { get set }
    var storage: Storage { get set }
    var body: Body { get set }
}

extension Message {
    public func set(_ value: Any?, key: String) {
        storage[key] = value
    }
    
    public func get<T>(_ key: String) throws -> T {
        guard let value = storage[key] else  {
            throw MessageError.valueNotFound(key: key)
        }
        
        guard let castedValue = value as? T else {
            throw MessageError.incompatibleType(requestedType: T.self, actualType: type(of: value))
        }
        
        return castedValue
    }
    
    public var contentType: MediaType? {
        get {
            return headers["Content-Type"].flatMap({try? MediaType(string: $0)})
        }
        
        set(contentType) {
            headers["Content-Type"] = contentType?.description
        }
    }
    
    public var contentLength: Int? {
        get {
            return headers["Content-Length"].flatMap({Int($0)})
        }
        
        set(contentLength) {
            headers["Content-Length"] = contentLength?.stringValue
        }
    }
    
    public var transferEncoding: String? {
        get {
            return headers["Transfer-Encoding"]
        }
        
        set(transferEncoding) {
            headers["Transfer-Encoding"] = transferEncoding
        }
    }
    
    public var isChunkEncoded: Bool {
        return transferEncoding == "chunked"
    }

    public var connection: String? {
        get {
            return headers["Connection"]
        }
        
        set(connection) {
            headers["Connection"] = connection
        }
    }

    public var isKeepAlive: Bool {
        if version.minor == 0 {
            return connection?.lowercased() == "keep-alive"
        }

        return connection?.lowercased() != "close"
    }

    public var isUpgrade: Bool {
        return connection?.lowercased() == "upgrade"
    }

    public var upgrade: String? {
        return headers["Upgrade"]
    }
    
    public func content<Content : MediaDecodable>(
        deadline: Deadline = 5.minutes.fromNow(),
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws -> Content {
        guard let mediaType = self.contentType else {
            throw MessageError.noContentTypeHeader
        }
        
        guard let readable = try? body.convertedToReadable() else {
            throw MessageError.noReadableBody
        }
        
        let media = try Content.decodingMedia(for: mediaType)
        return try media.decode(Content.self, from: readable, deadline: deadline, userInfo: userInfo)
    }
    
    public func content<Content : DecodingMedia>(
        deadline: Deadline = 5.minutes.fromNow(),
        userInfo: [CodingUserInfoKey: Any] = [:]
    ) throws -> Content {
        guard let readable = try? body.convertedToReadable() else {
            throw MessageError.noReadableBody
        }
        
        return try Content(from: readable, deadline: deadline)
    }
}
