import Foundation

class ConnectionPool : ConnectionQueryable {
    let config: ReqlConfig

    private var connections: [Connection] = []
    private let semaphore: DispatchSemaphore
    private let lock = NSRecursiveLock()

    init(config: ReqlConfig, maxConnections: Int = 10) {
        self.config = config
        self.semaphore = DispatchSemaphore(value: maxConnections)
    }

    func run(ast: ReqlAst) throws -> JSON {
        return try self.withConnection { try $0.run(ast: ast) }
    }

    private func withConnection<T>(handler: (Connection) throws -> T) throws -> T {
        // wait on the semaphore
        let waitTime = DispatchTime(uptimeNanoseconds: DispatchTime.now().uptimeNanoseconds + UInt64(NSEC_PER_SEC * 60))
        guard case .success = self.semaphore.wait(timeout: waitTime) else {
            throw Error(code: .connection, reason: "Could not get connection within 60 seconds.")
        }

        // defer a signal
        defer {
            self.semaphore.signal()
        }

        // get connection
        let connection: Connection
        if let existing = self.checkoutConnection() {
            connection = existing
        } else {
            connection = try self.makeConnection()
        }

        // use connection
        let result = try handler(connection)

        // check in connection
        self.checkin(connection: connection)

        // return result
        return result
    }

    private func checkoutConnection() -> Connection? {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        return self.connections.popLast()
    }

    private func checkin(connection: Connection) {
        self.lock.lock()
        defer {
            self.lock.unlock()
        }
        self.connections.insert(connection, at: 0)
    }

    private func makeConnection() throws -> Connection {
        return try Connection.connect(config: self.config)
    }
}
