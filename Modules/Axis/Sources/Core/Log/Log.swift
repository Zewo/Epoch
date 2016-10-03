#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public protocol Appender {
    var name: String { get }
    var levels: Logger.Level { get }
    func append(event: Logger.Event)
}

public final class Logger {
    public struct Level: OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let trace   = Level(rawValue: 1 << 0)
        public static let debug   = Level(rawValue: 1 << 1)
        public static let info    = Level(rawValue: 1 << 2)
        public static let warning = Level(rawValue: 1 << 3)
        public static let error   = Level(rawValue: 1 << 4)
        public static let fatal   = Level(rawValue: 1 << 5)
        public static let all     = Level(rawValue: ~0)
    }

    public struct Event {
        public let locationInfo: LocationInfo
        public let timestamp: String
        public let level: Logger.Level
        public let name: String
        public let logger: Logger
        public var message: Any? = nil
        public var error: Error? = nil
    }

    public struct LocationInfo {
        public let file: String
        public let line: Int
        public let column: Int
        public let function: String
    }

    var appenders = [Appender]()
    var name: String

    public init(name: String = "Logger", appenders: [Appender] = [StandardOutputAppender()]) {
        self.appenders.append(contentsOf: appenders)
        self.name = name
    }
}

extension Logger.LocationInfo : CustomStringConvertible {
    public var description: String {
        return "\(file):\(function):\(line):\(column)"
    }
}

extension Logger {
    private func log(level: Level, item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        let event = Event(
            locationInfo: LocationInfo(
                file: file,
                line: line,
                column: column,
                function: function
            ),
            timestamp: currentTime,
            level: level,
            name: self.name,
            logger: self,
            message: item,
            error: error
        )
        for apender in appenders {
            apender.append(event: event)
        }
    }

    public func trace(_ item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(
            level: .trace,
            item: item,
            error: error,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }

    public func debug(_ item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(
            level: .debug,
            item: item,
            error: error,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }

    public func info(_ item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(
            level: .info,
            item: item,
            error: error,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }

    public func warning(_ item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(
            level: .warning,
            item: item,
            error: error,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }

    public func error(_ item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(
            level: .error,
            item: item,
            error: error,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }

    public func fatal(_ item: Any?, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line, column: Int = #column) {
        log(
            level: .fatal,
            item: item,
            error: error,
            file: file,
            function: function,
            line: line,
            column: column
        )
    }

    private var currentTime: String {
      var tv = timeval()
      gettimeofday(&tv, nil)
      return String(tv.tv_sec)
    }
}
