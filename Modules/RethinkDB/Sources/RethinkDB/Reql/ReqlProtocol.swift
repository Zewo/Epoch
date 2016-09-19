class ReqlProtocol {
    // v1.0
    static let version: Int32 = 0x34c2bdc3

    // json
    static let type: Int32 = 0x7e6970c7

    enum QueryType: Int {
        case start = 1
        case `continue` = 2
        case stop = 3
        case noreplyWait = 4
        case serverInfo = 5
    }

    enum FrameType: Int {
        case pos = 1
        case opt = 2
    }

    enum ResponseType: Int {
        case successAtom = 1
        case successSequence = 2
        case successPartial = 3
        case waitComplete = 4
        case serverInfo = 5
        case clientError = 16
        case compileError = 17
        case runtimeError = 18
    }

    enum ResponseNoteType: Int {
        case sequenceFeed = 1
        case atomFeed = 2
        case orderByLimitFeed = 3
        case unionedFeed = 4
        case includesStates = 5
    }


    enum ResponseErrorType: Int {
        case `internal` = 1000000
        case resourceLimit = 2000000
        case queryLogic = 3000000
        case nonExistence = 3100000
        case opFailed = 4100000
        case opIndeterminate = 4200000
        case user = 5000000
        case permissionError = 6000000
    }
}
