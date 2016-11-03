@_exported import SQL
import CLibpq
import Axis

public struct ConnectionError: Error, CustomStringConvertible {
    public let description: String
}

public final class Connection: ConnectionProtocol {
    public typealias QueryRenderer = PostgreSQL.QueryRenderer

    public struct ConnectionInfo: ConnectionInfoProtocol {
        public var host: String
        public var port: Int
        public var databaseName: String
        public var username: String?
        public var password: String?
        public var options: String?
        public var tty: String?

        public init?(uri: URL) {
            do {
                try self.init(uri)
            } catch {
                return nil
            }
        }

        public init(_ uri: URL) throws {
            let databaseName = uri.path.trim(["/"])

            guard let host = uri.host, let port = uri.port else {
                throw ConnectionError(description: "Failed to extract host, port, database name from URI")
            }

            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.username = uri.user
            self.password = uri.password
        }

        public init(host: String, port: Int = 5432, databaseName: String, username: String? = nil, password: String? = nil, options: String? = nil, tty: String? = nil) {
            self.host = host
            self.port = port
            self.databaseName = databaseName
            self.username = username
            self.password = password
            self.options = options
            self.tty = tty
        }
    }

    public enum InternalStatus {
        case Bad
        case Started
        case Made
        case AwatingResponse
        case AuthOK
        case SettingEnvironment
        case SSLStartup
        case OK
        case Unknown
        case Needed

        public init(status: ConnStatusType) {
            switch status {
            case CONNECTION_NEEDED:
                self = .Needed
                break
            case CONNECTION_OK:
                self = .OK
                break
            case CONNECTION_STARTED:
                self = .Started
                break
            case CONNECTION_MADE:
                self = .Made
                break
            case CONNECTION_AWAITING_RESPONSE:
                self = .AwatingResponse
                break
            case CONNECTION_AUTH_OK:
                self = .AuthOK
                break
            case CONNECTION_SSL_STARTUP:
                self = .SSLStartup
                break
            case CONNECTION_SETENV:
                self = .SettingEnvironment
                break
            case CONNECTION_BAD:
                self = .Bad
                break
            default:
                self = .Unknown
                break
            }
        }
    }

    public var logger: Logger?

    private var connection: OpaquePointer? = nil

    public let connectionInfo: ConnectionInfo

    public required init(info: ConnectionInfo) {
        self.connectionInfo = info
    }

    deinit {
        close()
    }

    public var internalStatus: InternalStatus {
        return InternalStatus(status: PQstatus(self.connection))
    }

    public func open() throws {
        connection = PQsetdbLogin(
            connectionInfo.host,
            String(connectionInfo.port),
            connectionInfo.options ?? "",
            connectionInfo.tty ?? "",
            connectionInfo.databaseName,
            connectionInfo.username ?? "",
            connectionInfo.password ?? ""
        )

        if let error = mostRecentError {
            throw error
        }
    }

    public var mostRecentError: ConnectionError? {
        guard let errorString = String(validatingUTF8: PQerrorMessage(connection)), !errorString.isEmpty else {
            return nil
        }

        return ConnectionError(description: errorString)
    }

    public func close() {
        PQfinish(connection)
        connection = nil
    }

    public func createSavePointNamed(_ name: String) throws {
        try execute("SAVEPOINT \(name)", parameters: nil)
    }

    public func rollbackToSavePointNamed(_ name: String) throws {
        try execute("ROLLBACK TO SAVEPOINT \(name)", parameters: nil)
    }

    public func releaseSavePointNamed(_ name: String) throws {
        try execute("RELEASE SAVEPOINT \(name)", parameters: nil)
    }

    @discardableResult
    public func execute(_ statement: String, parameters: [Value?]?) throws -> Result {

        var statement = statement.sqlStringWithEscapedPlaceholdersUsingPrefix("$") {
            return String($0 + 1)
        }

        defer { logger?.debug(statement) }

        guard let parameters = parameters else {
            guard let resultPointer = PQexec(connection, statement) else {
                throw mostRecentError ?? ConnectionError(description: "Empty result")
            }

            return try Result(resultPointer)
        }

        var parameterData = [UnsafePointer<Int8>?]()
        var deallocators = [() -> ()]()
        defer { deallocators.forEach { $0() } }

        for parameter in parameters {

            guard let value = parameter else {
                parameterData.append(nil)
                continue
            }

            let data: AnyCollection<Int8>
            switch value {
            case .buffer(let value):
                data = AnyCollection(value.map { Int8($0) })

            case .string(let string):
                data = AnyCollection(string.utf8CString)
            }

            let pointer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(data.count))
            deallocators.append {
                pointer.deallocate(capacity: Int(data.count))
            }

            for (index, byte) in data.enumerated() {
                pointer[index] = byte
            }

            parameterData.append(pointer)
        }

        let result: OpaquePointer = try parameterData.withUnsafeBufferPointer { buffer in
            guard let result = PQexecParams(
                self.connection,
                statement,
                Int32(parameters.count),
                nil,
                buffer.isEmpty ? nil : buffer.baseAddress,
                nil,
                nil,
                0
                ) else {
                    throw mostRecentError ?? ConnectionError(description: "Empty result")
            }
            return result
        }

        return try Result(result)
    }
}
