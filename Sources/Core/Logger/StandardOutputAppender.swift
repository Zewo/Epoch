public struct StandardOutputAppender : LogAppender {
    public let name: String
    public let levels: Logger.Level

    public init(name: String = "Standard Output Appender", levels: Logger.Level = .all) {
        self.name = name
        self.levels = levels
    }

    public func append(event: Logger.Event) {
        var logMessage = ""

        logMessage += "[" + event.timestamp.description + "]"
        logMessage += "[" + event.locationInfo.description + "]"

        if let message = event.message {
            logMessage += ":" + String(describing: message)
        }

        if let error = event.error {
            logMessage += ":" + String(describing: error)
        }

        print(logMessage)
    }
}
