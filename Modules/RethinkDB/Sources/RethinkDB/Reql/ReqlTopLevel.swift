import Foundation

public class ReqlTopLevel : ReqlAst {
    public static func expr(_ value: Any) -> ReqlExpr {
        return ReqlExpr(term: .datum, args: [value], parent: nil)
    }

    public static var config: ReqlConfig {
        get {
            return self.connectionPool.config
        }
        set {
            self.connectionPool = ConnectionPool(config: newValue)
        }
    }

    internal static var connectionPool: ConnectionPool {
        get {
            self.connectionPoolLock.lock()
            let value = self.connectionPoolValue
            self.connectionPoolLock.unlock()
            return value
        }
        set {
            self.connectionPoolLock.lock()
            self.connectionPoolValue = newValue
            self.connectionPoolLock.unlock()
        }
    }

    private static let connectionPoolLock = NSRecursiveLock()

    private static var connectionPoolValue = ConnectionPool(
        config: ReqlConfig(connect: {
            throw Error(code: .connection, reason: "Transport not configured.")
        })
    )
}

public typealias r = ReqlTopLevel
