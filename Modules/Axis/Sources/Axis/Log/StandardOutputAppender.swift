public class StandardOutputAppender : Appender {
    public let name: String
    public var levels: Logger.Level
    var lastMessage: String = ""

    public init(name: String = "Standard Output Appender", levels: Logger.Level = .all) {
        self.name = name
        self.levels = levels
    }

    public func append(event: Logger.Event) {
        var logMessage = ""

        defer {
            lastMessage = logMessage
        }

        guard levels.contains(event.level) else {
            return
        }

        logMessage += "[" + event.timestamp + "]"
        logMessage += "[" + String(describing: event.locationInfo) + "]"

        if let message = event.message {
            logMessage += ":" + String(describing: message)
        }

        if let error = event.error {
            logMessage += ":" + String(describing: error)
        }

        print(logMessage)
    }
}
