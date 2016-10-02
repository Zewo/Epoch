public struct Response : Message {
    public enum Status {
        case `continue`
        case switchingProtocols
        case processing

        case ok
        case created
        case accepted
        case nonAuthoritativeInformation
        case noContent
        case resetContent
        case partialContent

        case multipleChoices
        case movedPermanently
        case found
        case seeOther
        case notModified
        case useProxy
        case switchProxy
        case temporaryRedirect
        case permanentRedirect

        case badRequest
        case unauthorized
        case paymentRequired
        case forbidden
        case notFound
        case methodNotAllowed
        case notAcceptable
        case proxyAuthenticationRequired
        case requestTimeout
        case conflict
        case gone
        case lengthRequired
        case preconditionFailed
        case requestEntityTooLarge
        case requestURITooLong
        case unsupportedMediaType
        case requestedRangeNotSatisfiable
        case expectationFailed
        case imATeapot
        case authenticationTimeout
        case enhanceYourCalm
        case unprocessableEntity
        case locked
        case failedDependency
        case preconditionRequired
        case tooManyRequests
        case requestHeaderFieldsTooLarge

        case internalServerError
        case notImplemented
        case badGateway
        case serviceUnavailable
        case gatewayTimeout
        case httpVersionNotSupported
        case variantAlsoNegotiates
        case insufficientStorage
        case loopDetected
        case notExtended
        case networkAuthenticationRequired
        
        case other(statusCode: Int, reasonPhrase: String)
    }

    public var version: Version
    public var status: Status
    public var headers: Headers
    public var cookieHeaders: Set<String>
    public var body: Body
    public var storage: [String: Any] = [:]

    public init(version: Version, status: Status, headers: Headers, cookieHeaders: Set<String>, body: Body) {
        self.version = version
        self.status = status
        self.headers = headers
        self.cookieHeaders = cookieHeaders
        self.body = body
    }
}

public protocol ResponseInitializable {
    init(response: Response)
}

public protocol ResponseRepresentable {
    var response: Response { get }
}

public protocol ResponseConvertible : ResponseInitializable, ResponseRepresentable {}

extension Response : ResponseConvertible {
    public init(response: Response) {
        self = response
    }

    public var response: Response {
        return self
    }
}

extension Response {
    public init(status: Status = .ok, headers: Headers = [:], body: Body) {
        self.init(
            version: Version(major: 1, minor: 1),
            status: status,
            headers: headers,
            cookieHeaders: [],
            body: body
        )

        switch body {
        case let .buffer(body):
            self.headers["Content-Length"] = body.count.description
        default:
            self.headers["Transfer-Encoding"] = "chunked"
        }
    }

    public init(status: Status = .ok, headers: Headers = [:], body: BufferRepresentable = Buffer()) {
        self.init(
            status: status,
            headers: headers,
            body: .buffer(body.buffer)
        )
    }

    public init(status: Status = .ok, headers: Headers = [:], body: InputStream) {
        self.init(
            status: status,
            headers: headers,
            body: .reader(body)
        )
    }

    public init(status: Status = .ok, headers: Headers = [:], body: @escaping (OutputStream) throws -> Void) {
        self.init(
            status: status,
            headers: headers,
            body: .writer(body)
        )
    }
}

extension Response {
    public var statusCode: Int {
        return status.statusCode
    }

    public var isInformational: Bool {
        return status.isInformational
    }

    public var isSuccessfull: Bool {
        return status.isSuccessful
    }

    public var isRedirection: Bool {
        return status.isRedirection
    }

    public var isError: Bool {
        return status.isError
    }

    public var isClientError: Bool {
        return status.isClientError
    }

    public var isServerError: Bool {
        return status.isServerError
    }

    public var reasonPhrase: String {
        return status.reasonPhrase
    }
}

extension Response {
    public var cookies: Set<AttributedCookie> {
        get {
            var cookies = Set<AttributedCookie>()

            for header in cookieHeaders {
                if let cookie = AttributedCookie(header) {
                    cookies.insert(cookie)
                }
            }

            return cookies
        }

        set(cookies) {
            var headers = Set<String>()

            for cookie in cookies {
                let header = String(describing: cookie)
                headers.insert(header)
            }

            cookieHeaders = headers
        }
    }
}

extension Response {
    public typealias UpgradeConnection = (Request, Stream) throws -> Void

    public var upgradeConnection: UpgradeConnection? {
        return storage["response-connection-upgrade"] as? UpgradeConnection
    }

    public mutating func upgradeConnection(_ upgrade: @escaping UpgradeConnection)  {
        storage["response-connection-upgrade"] = upgrade
    }
}

extension Response : CustomStringConvertible {
    public var statusLineDescription: String {
        return "HTTP/" + String(version.major) + "." + String(version.minor) + " " + String(statusCode) + " " + reasonPhrase + "\n"
    }

    public var description: String {
        return statusLineDescription +
            headers.description
    }
}

extension Response : CustomDebugStringConvertible {
    public var debugDescription: String {
        return description + "\n" + storageDescription
    }
}
