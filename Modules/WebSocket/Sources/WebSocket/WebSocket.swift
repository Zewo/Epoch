import Axis
import struct Foundation.Data

public enum WebSocketError : Error {
    case noFrame
    case invalidOpCode
    case maskedFrameFromServer
    case unaskedFrameFromClient
    case controlFrameNotFinal
    case controlFrameInvalidLength
    case continuationOutOfOrder
    case dataFrameWithInvalidBits
    case maskKeyInvalidLength
    case noMaskKey
    case invalidUTF8Payload
    case invalidCloseCode
}

public final class WebSocket {
    fileprivate static let GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    public let bufferSize = 4096

    public enum Mode {
        case server
        case client
    }

    fileprivate enum State {
        case header
        case headerExtra
        case payload
    }

    fileprivate enum CloseState {
        case open
        case serverClose
        case clientClose
    }

    public let mode: Mode

    fileprivate let stream: Axis.Stream
    fileprivate var state: State = .header
    fileprivate var closeState: CloseState = .open

    fileprivate var incompleteFrame: Frame?
    fileprivate var continuationFrames: [Frame] = []

    fileprivate let binaryEventEmitter = EventEmitter<Buffer>()
    fileprivate let textEventEmitter = EventEmitter<String>()
    fileprivate let pingEventEmitter = EventEmitter<Buffer>()
    fileprivate let pongEventEmitter = EventEmitter<Buffer>()
    fileprivate let closeEventEmitter = EventEmitter<(code: CloseCode?, reason: String?)>()
    
    fileprivate let connectionTimeout: Double

    public init(stream: Axis.Stream, mode: Mode, connectionTimeout: Double = 60.seconds) {
        self.stream = stream
        self.mode = mode
        self.connectionTimeout = connectionTimeout
    }

    @discardableResult
    public func onBinary(_ listen: @escaping EventListener<Buffer>.Listen) -> EventListener<Buffer> {
        return binaryEventEmitter.addListener(listen: listen)
    }

    @discardableResult
    public func onText(_ listen: @escaping EventListener<String>.Listen) -> EventListener<String> {
        return textEventEmitter.addListener(listen: listen)
    }

    @discardableResult
    public func onPing(_ listen: @escaping EventListener<Buffer>.Listen) -> EventListener<Buffer> {
        return pingEventEmitter.addListener(listen: listen)
    }

    @discardableResult
    public func onPong(_ listen: @escaping EventListener<Buffer>.Listen) -> EventListener<Buffer> {
        return pongEventEmitter.addListener(listen: listen)
    }

    @discardableResult
    public func onClose(_ listen: @escaping EventListener<(code: CloseCode?, reason: String?)>.Listen) -> EventListener<(code: CloseCode?, reason: String?)> {
        return closeEventEmitter.addListener(listen: listen)
    }

    public func send(_ string: String) throws {
        try send(.text, data: Buffer(string))
    }

    public func send(_ data: Buffer) throws {
        try send(.binary, data: data)
    }

    public func send(_ convertible: BufferConvertible) throws {
        try send(.binary, data: convertible.buffer)
    }

    public func close(_ code: CloseCode = .normal, reason: String? = nil) throws {
        if closeState == .serverClose {
            return
        }

        if closeState == .open {
            closeState = .serverClose
        }

        var data = Buffer(number: code.code)

        if let reason = reason {
            data.append(Buffer(reason))
        }

        if closeState == .serverClose && code == .protocolError {
            stream.close()
        }

        try send(.close, data: data)

        if closeState == .clientClose {
            stream.close()
        }
    }

    public func ping(_ data: Buffer = Buffer()) throws {
        try send(.ping, data: data)
    }

    public func ping(_ convertible: BufferConvertible) throws {
        try send(.ping, data: convertible.buffer)
    }

    public func pong(_ data: Buffer = Buffer()) throws {
        try send(.pong, data: data)
    }

    public func pong(_ convertible: BufferConvertible) throws {
        try send(.pong, data: convertible.buffer)
    }

    public func start() throws {
        while !stream.closed {
            do {
                let data = try stream.read(upTo: self.bufferSize, deadline: connectionTimeout.fromNow())
                try processData(data)
            } catch StreamError.closedStream {
                break
            }
        }
        if closeState == .open {
            try closeEventEmitter.emit((code: .abnormal, reason: nil))
        }
    }

    fileprivate func processData(_ data: Buffer) throws {
        guard data.count > 0 else {
            return
        }

        var totalBytesRead = 0

        while totalBytesRead < data.count {
            let bytesRead = try readBytes(data[totalBytesRead..<data.count])

            if bytesRead == 0 {
                break
            }

            totalBytesRead += bytesRead
        }
    }

    fileprivate func readBytes(_ data: Buffer) throws -> Int {
        if data.count == 0 {
            return 0
        }

        var remainingData = data

        repeat {
            if incompleteFrame == nil {
                incompleteFrame = Frame()
            }

            // Use ! because if let will add data to a copy of the frame
            remainingData = incompleteFrame!.add(remainingData)

            if incompleteFrame!.isComplete {
                try validateFrame(incompleteFrame!)
                try processFrame(incompleteFrame!)
                incompleteFrame = nil
            }
        } while remainingData.count > 0

        return data.count
    }

    fileprivate func validateFrame(_ frame: Frame) throws {
        func fail(_ error: Error) throws -> Error {
            try close(.protocolError)
            return error
        }

        guard !frame.rsv1 && !frame.rsv2 && !frame.rsv3 else {
            throw try fail(WebSocketError.dataFrameWithInvalidBits)
        }

        guard frame.opCode != .invalid else {
            throw try fail(WebSocketError.invalidOpCode)
        }

        guard !frame.masked || self.mode == .server else {
            throw try fail(WebSocketError.maskedFrameFromServer)
        }

        guard frame.masked || self.mode == .client else {
            throw try fail(WebSocketError.unaskedFrameFromClient)
        }

        if frame.opCode.isControl {
            guard frame.fin else {
                throw try fail(WebSocketError.controlFrameNotFinal)
            }

            guard frame.payloadLength < 126 else {
                throw try fail(WebSocketError.controlFrameInvalidLength)
            }

            if frame.opCode == .close && frame.payloadLength == 1 {
                throw try fail(WebSocketError.controlFrameInvalidLength)
            }
        } else {
            if frame.opCode == .continuation && continuationFrames.isEmpty {
                throw try fail(WebSocketError.continuationOutOfOrder)
            }

            if frame.opCode != .continuation && !continuationFrames.isEmpty {
                throw try fail(WebSocketError.continuationOutOfOrder)
            }


        }
    }

    fileprivate func processFrame(_ frame: Frame) throws {
        func fail(_ error: Error) throws -> Error {
            try close(.protocolError)
            return error
        }

        if !frame.opCode.isControl {
            continuationFrames.append(frame)
        }

        if !frame.fin {
            return
        }

        var opCode = frame.opCode


        if frame.opCode == .continuation {
            let firstFrame = continuationFrames.first!
            opCode = firstFrame.opCode
        }

        switch opCode {
        case .binary:
            try binaryEventEmitter.emit(continuationFrames.payload)
        case .text:
            if (try? String(buffer: continuationFrames.payload)) == nil {
                throw try fail(WebSocketError.invalidUTF8Payload)
            }
            try textEventEmitter.emit(try String(buffer: continuationFrames.payload))
        case .ping:
            try pingEventEmitter.emit(frame.payload)
        case .pong:
            try pongEventEmitter.emit(frame.payload)
        case .close:
            if self.closeState == .open {
                var rawCloseCode: UInt16?
                var closeReason: String?
                var data = frame.payload

                if data.count >= 2 {
                    rawCloseCode = UInt16(data[0..<2].buffer.toInt(2))
                    data = data[2..<data.count].buffer // TODO: is this efficient?

                    if data.count > 0 {
                        closeReason = try? String(buffer:data)
                    }

                    if data.count > 0 && closeReason == nil {
                        throw try fail(WebSocketError.invalidUTF8Payload)
                    }
                }

                closeState = .clientClose

                if let rawCloseCode = rawCloseCode {
                    let closeCode = CloseCode(code: rawCloseCode)
                    if closeCode.isValid {
                        try close(closeCode , reason: closeReason)
                        try closeEventEmitter.emit((closeCode, closeReason))
                    } else {
                        throw try fail(WebSocketError.invalidCloseCode)
                    }
                } else {
                    try close(reason: nil)
                    try closeEventEmitter.emit((nil, nil))
                }
            } else if self.closeState == .serverClose {
                stream.close()
            }
        default:
            break
        }

        if !frame.opCode.isControl {
            continuationFrames.removeAll()
        }
    }

    fileprivate func send(_ opCode: Frame.OpCode, data: Buffer) throws {
        let maskKey: Buffer
        if mode == .client {
            maskKey = try Buffer(randomBytes: 4)
        } else {
            maskKey = Buffer()
        }
        let frame = Frame(opCode: opCode, data: data, maskKey: maskKey)
        let data = frame.data
        try stream.write(data, deadline: 5.seconds.fromNow())
        try stream.flush(deadline: 5.seconds.fromNow())
    }

    public static func accept(_ key: String) -> String? {
        let hashed = sha1(Array((key + GUID).utf8))

        let encoded = Data(bytes: hashed).base64EncodedString(options: [])
        return encoded

    }
}
