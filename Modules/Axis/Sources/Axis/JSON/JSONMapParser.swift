#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CYAJL

public struct JSONMapParserOptions : OptionSet {
    public let rawValue: Int
    public static let allowComments = JSONMapParserOptions(rawValue: 1 << 0)
    public static let dontValidateStrings = JSONMapParserOptions(rawValue: 1 << 1)
    public static let allowTrailingGarbage = JSONMapParserOptions(rawValue: 1 << 2)
    public static let allowMultipleValues = JSONMapParserOptions(rawValue: 1 << 3)
    public static let allowPartialValues = JSONMapParserOptions(rawValue: 1 << 4)

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

public struct JSONMapParserError : Error, CustomStringConvertible {
    let reason: String

    public var description: String {
        return reason
    }
}

public final class JSONMapParser : MapParser {
    public static func parse(_ bytes: UnsafeBufferPointer<Byte>, options: JSONMapParserOptions = []) throws -> Map {
        let parser = JSONMapParser(options: options)
        try parser.parse(bytes)
        return try parser.finish()
    }

    public static func parse(_ bytes: [Byte], options: JSONMapParserOptions = []) throws -> Map {
        return try bytes.withUnsafeBufferPointer {
            try self.parse($0, options: options)
        }
    }

    public let options: JSONMapParserOptions

    fileprivate var state: JSONMapParserState = JSONMapParserState(dictionary: true)
    fileprivate var stack: [JSONMapParserState] = []

    fileprivate let bufferCapacity = 8*1024
    fileprivate let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: 8*1024)

    fileprivate var result: Map? = nil

    fileprivate var handle: yajl_handle!

    public convenience init() {
        self.init(options: [])
    }

    public init(options: JSONMapParserOptions = []) {
        self.options = options
        self.state.dictionaryKey = "root"
        self.stack.reserveCapacity(12)

        handle = yajl_alloc(&yajl_handle_callbacks,
                            nil,
                            Unmanaged.passUnretained(self).toOpaque())

        yajl_config_set(handle, yajl_allow_comments, options.contains(.allowComments) ? 1 : 0)
        yajl_config_set(handle, yajl_dont_validate_strings, options.contains(.dontValidateStrings) ? 1 : 0)
        yajl_config_set(handle, yajl_allow_trailing_garbage, options.contains(.allowTrailingGarbage) ? 1 : 0)
        yajl_config_set(handle, yajl_allow_multiple_values, options.contains(.allowMultipleValues) ? 1 : 0)
        yajl_config_set(handle, yajl_allow_partial_values, options.contains(.allowPartialValues) ? 1 : 0)

    }
    deinit {
        yajl_free(handle)
        buffer.deallocate(capacity: bufferCapacity)
    }

    @discardableResult
    public func parse(_ bytes: UnsafeBufferPointer<Byte>) throws -> Map? {
        let final = bytes.isEmpty

        guard result == nil else {
            guard final else {
                throw JSONMapParserError(reason: "Unexpected bytes. Parser already completed.")
            }
            return result
        }

        let status: yajl_status
        if !final {
            status = yajl_parse(handle, bytes.baseAddress!, bytes.count)
        } else {
            status = yajl_complete_parse(handle)
        }

        guard status == yajl_status_ok else {
            let reasonBytes = yajl_get_error(handle, 1, bytes.baseAddress!, bytes.count)
            defer {
                yajl_free_error(handle, reasonBytes)
            }
            let reason = String(cString: reasonBytes!)
            throw JSONMapParserError(reason: reason)
        }

        if stack.count == 0 || final {
            switch state.map {
            case .dictionary(let value):
                result = value["root"]
            default:
                break
            }
        }

        guard !final || result != nil else {
            throw JSONMapParserError(reason: "Unexpected end of bytes.")
        }

        return result
    }

    public func finish() throws -> Map {
        let bytes: [Byte] = []
        guard let result = try bytes.withUnsafeBufferPointer({ try self.parse($0) }) else {
            throw JSONMapParserError(reason: "Unexpected end of bytes.")
        }
        return result
    }

    fileprivate func appendNull() -> Int32 {
        return state.appendNull()
    }

    fileprivate func appendBoolean(_ value: Bool) -> Int32 {
        return state.append(value)
    }

    fileprivate func appendInteger(_ value: Int64) -> Int32 {
        return state.append(value)
    }

    fileprivate func appendDouble(_ value: Double) -> Int32 {
        return state.append(value)
    }

    fileprivate func appendString(_ value: String) -> Int32 {
        return state.append(value)
    }

    fileprivate func startMap() -> Int32 {
        stack.append(state)
        state = JSONMapParserState(dictionary: true)
        return 1
    }

    fileprivate func mapKey(_ key: String) -> Int32 {
        state.dictionaryKey = key
        return 1
    }

    fileprivate func endMap() -> Int32 {
        if stack.count == 0 {
            return 0
        }
        var previousState = stack.removeLast()
        let result: Int32 = previousState.append(state.map)
        state = previousState
        return result
    }

    fileprivate func startArray() -> Int32 {
        stack.append(state)
        state = JSONMapParserState(dictionary: false)
        return 1
    }

    fileprivate func endArray() -> Int32 {
        if stack.count == 0 {
            return 0
        }
        var previousState = stack.removeLast()
        let result: Int32 = previousState.append(state.map)
        state = previousState
        return result
    }

}

fileprivate struct JSONMapParserState {
    let isDictionary: Bool
    var dictionaryKey: String = ""

    var map: Map {
        if isDictionary {
            return .dictionary(dictionary)
        } else {
            return .array(array)
        }
    }

    private var dictionary: [String: Map]
    private var array: [Map]

    init(dictionary: Bool) {
        self.isDictionary = dictionary
        if dictionary {
            self.dictionary = Dictionary<String, Map>(minimumCapacity: 32)
            self.array = []
        } else {
            self.dictionary = [:]
            self.array = []
            self.array.reserveCapacity(32)
        }
    }

    mutating func append(_ value: Bool) -> Int32 {
        if isDictionary {
            dictionary[dictionaryKey] = .bool(value)
        } else {
            array.append(.bool(value))
        }
        return 1
    }

    mutating func append(_ value: Int64) -> Int32 {
        if isDictionary {
            dictionary[self.dictionaryKey] = .int(Int(value))
        } else {
            array.append(.int(Int(value)))
        }
        return 1
    }

    mutating func append(_ value: Double) -> Int32 {
        if isDictionary {
            dictionary[dictionaryKey] = .double(value)
        } else {
            array.append(.double(value))
        }
        return 1
    }

    mutating func append(_ value: String) -> Int32 {
        if isDictionary {
            dictionary[dictionaryKey] = .string(value)
        } else {
            array.append(.string(value))
        }
        return 1
    }

    mutating func appendNull() -> Int32 {
        if isDictionary {
            dictionary[dictionaryKey] = .null
        } else {
            array.append(.null)
        }
        return 1
    }

    mutating func append(_ value: Map) -> Int32 {
        if isDictionary {
            dictionary[dictionaryKey] = value
        } else {
            array.append(value)
        }
        return 1
    }
}

fileprivate var yajl_handle_callbacks = yajl_callbacks(
    yajl_null: yajl_null,
    yajl_boolean: yajl_boolean,
    yajl_integer: yajl_integer,
    yajl_double: yajl_double,
    yajl_number: nil,
    yajl_string: yajl_string,
    yajl_start_map: yajl_start_map,
    yajl_map_key: yajl_map_key,
    yajl_end_map: yajl_end_map,
    yajl_start_array: yajl_start_array,
    yajl_end_array: yajl_end_array
)

fileprivate func yajl_null(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.appendNull()
}

fileprivate func yajl_boolean(_ ptr: UnsafeMutableRawPointer?, value: Int32) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.appendBoolean(value != 0)
}

fileprivate func yajl_integer(_ ptr: UnsafeMutableRawPointer?, value: Int64) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.appendInteger(value)
}

fileprivate func yajl_double(_ ptr: UnsafeMutableRawPointer?, value: Double) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.appendDouble(value)
}

fileprivate func yajl_string(_ ptr: UnsafeMutableRawPointer?, buffer: UnsafePointer<Byte>?, bufferLength: Int) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()

    let str: String
    if bufferLength > 0 {
        if bufferLength < ctx.bufferCapacity {
            memcpy(UnsafeMutableRawPointer(ctx.buffer), UnsafeRawPointer(buffer!), bufferLength)
            ctx.buffer[bufferLength] = 0
            str = String(cString: UnsafePointer(ctx.buffer))
        } else {
            var buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength + 1)
            defer { buffer.deallocate(capacity: bufferLength + 1) }
            buffer[bufferLength] = 0
            str = String(cString: UnsafePointer(buffer))
        }
    } else {
        str = ""
    }

    return ctx.appendString(str)
}

fileprivate func yajl_start_map(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.startMap()
}

fileprivate func yajl_map_key(_ ptr: UnsafeMutableRawPointer?, buffer: UnsafePointer<Byte>?, bufferLength: Int) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()

    let str: String
    if bufferLength > 0 {
        if bufferLength < ctx.bufferCapacity {
            memcpy(UnsafeMutableRawPointer(ctx.buffer), UnsafeRawPointer(buffer!), bufferLength)
            ctx.buffer[bufferLength] = 0
            str = String(cString: UnsafePointer(ctx.buffer))
        } else {
            var buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength + 1)
            defer { buffer.deallocate(capacity: bufferLength + 1) }
            buffer[bufferLength] = 0
            str = String(cString: UnsafePointer(buffer))
        }
    } else {
        str = ""
    }

    return ctx.mapKey(str)
}

fileprivate func yajl_end_map(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.endMap()
}

fileprivate func yajl_start_array(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.startArray()
}

fileprivate func yajl_end_array(_ ptr: UnsafeMutableRawPointer?) -> Int32 {
    let ctx = Unmanaged<JSONMapParser>.fromOpaque(ptr!).takeUnretainedValue()
    return ctx.endArray()
}
