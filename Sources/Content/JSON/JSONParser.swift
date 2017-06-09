#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

import CYAJL

public struct JSONParserError : Error, CustomStringConvertible {
    public let description: String
}

public final class JSONParser {
    public struct Options : OptionSet {
        public let rawValue: Int
        public static let allowComments = Options(rawValue: 1 << 0)
        public static let dontValidateStrings = Options(rawValue: 1 << 1)
        public static let allowTrailingGarbage = Options(rawValue: 1 << 2)
        public static let allowMultipleValues = Options(rawValue: 1 << 3)
        public static let allowPartialValues = Options(rawValue: 1 << 4)
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }
    
    public static func parse(_ bytes: UnsafeRawBufferPointer, options: Options = []) throws -> JSON {
        let parser = JSONParser(options: options)
        try parser.parse(bytes)
        return try parser.finish()
    }
    
    public let options: Options
    
    fileprivate var state: JSONParserState = JSONParserState(dictionary: true)
    fileprivate var stack: [JSONParserState] = []
    
    fileprivate let bufferCapacity = 8*1024
    fileprivate let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: 8 * 1024)
    
    fileprivate var result: JSON? = nil
    
    fileprivate var handle: yajl_handle?
    
    public convenience init() {
        self.init(options: [])
    }
    
    public init(options: Options = []) {
        self.options = options
        self.state.dictionaryKey = "root"
        self.stack.reserveCapacity(12)
        
        handle = yajl_alloc(
            &yajl_handle_callbacks,
            nil,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
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
    public func parse(_ bytes: UnsafeRawBufferPointer) throws -> JSON? {
        let final = bytes.isEmpty
        
        guard result == nil else {
            guard final else {
                throw JSONParserError(description: "Unexpected bytes. Parser already completed.")
            }
            
            return result
        }
        
        let status: yajl_status
        
        if !final {
            status = yajl_parse(
                handle,
                bytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                bytes.count
            )
        } else {
            status = yajl_complete_parse(handle)
        }
        
        guard status == yajl_status_ok else {
            let reasonBytes = yajl_get_error(
                handle,
                1,
                bytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                bytes.count
            )
            
            defer {
                yajl_free_error(handle, reasonBytes)
            }
            
            guard let reason = reasonBytes else {
                throw JSONParserError(description: "Unkown error while parsing JSON.")
            }
            
            throw JSONParserError(description: String(cString: reason))
        }
        
        if stack.count == 0 || final {
            switch state.json {
            case .object(let object):
                result = object["root"]
            default:
                break
            }
        }
        
        guard !final || result != nil else {
            throw JSONParserError(description: "Unexpected end of bytes.")
        }
        
        return result
    }
    
    public func finish() throws -> JSON {
        let empty = UnsafeRawBufferPointer(start: nil, count: 0)
        
        guard let result = try self.parse(empty) else {
            throw JSONParserError(description: "Unexpected end of bytes.")
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
        state = JSONParserState(dictionary: true)
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
        let result: Int32 = previousState.append(state.json)
        state = previousState
        return result
    }
    
    fileprivate func startArray() -> Int32 {
        stack.append(state)
        state = JSONParserState(dictionary: false)
        return 1
    }
    
    fileprivate func endArray() -> Int32 {
        if stack.count == 0 {
            return 0
        }
        
        var previousState = stack.removeLast()
        let result: Int32 = previousState.append(state.json)
        state = previousState
        return result
    }
}

fileprivate struct JSONParserState {
    let isDictionary: Bool
    var dictionaryKey: String = ""
    
    var json: JSON {
        if isDictionary {
            return .object(object)
        } else {
            return .array(array)
        }
    }
    
    private var object: [String: JSON]
    private var array: [JSON]
    
    init(dictionary: Bool) {
        self.isDictionary = dictionary
        if dictionary {
            self.object = Dictionary<String, JSON>(minimumCapacity: 32)
            self.array = []
        } else {
            self.object = [:]
            self.array = []
            self.array.reserveCapacity(32)
        }
    }
    
    mutating func append(_ value: Bool) -> Int32 {
        if isDictionary {
            object[dictionaryKey] = .bool(value)
        } else {
            array.append(.bool(value))
        }
        
        return 1
    }
    
    mutating func append(_ value: Int64) -> Int32 {
        if isDictionary {
            object[self.dictionaryKey] = .int(Int(value))
        } else {
            array.append(.int(Int(value)))
        }
        
        return 1
    }
    
    mutating func append(_ value: Double) -> Int32 {
        if isDictionary {
            object[dictionaryKey] = .double(value)
        } else {
            array.append(.double(value))
        }
        
        return 1
    }
    
    mutating func append(_ value: String) -> Int32 {
        if isDictionary {
            object[dictionaryKey] = .string(value)
        } else {
            array.append(.string(value))
        }
        
        return 1
    }
    
    mutating func appendNull() -> Int32 {
        if isDictionary {
            object[dictionaryKey] = .null
        } else {
            array.append(.null)
        }
        
        return 1
    }
    
    mutating func append(_ value: JSON) -> Int32 {
        if isDictionary {
            object[dictionaryKey] = value
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

fileprivate func yajl_null(_ pointer: UnsafeMutableRawPointer?) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.appendNull()
}

fileprivate func yajl_boolean(_ pointer: UnsafeMutableRawPointer?, value: Int32) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.appendBoolean(value != 0)
}

fileprivate func yajl_integer(_ pointer: UnsafeMutableRawPointer?, value: Int64) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.appendInteger(value)
}

fileprivate func yajl_double(_ pointer: UnsafeMutableRawPointer?, value: Double) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.appendDouble(value)
}

fileprivate func yajl_string(
    _ pointer: UnsafeMutableRawPointer?,
    buffer: UnsafePointer<UInt8>?,
    bufferLength: Int
) -> Int32 {
    guard let buffer = buffer else {
        return 0
    }
    
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    let string: String
    
    if bufferLength > 0 {
        if bufferLength < parser.bufferCapacity {
            memcpy(UnsafeMutableRawPointer(parser.buffer), UnsafeRawPointer(buffer), bufferLength)
            parser.buffer[bufferLength] = 0
            string = String(cString: UnsafePointer(parser.buffer))
        } else {
            var newBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength + 1)
            defer { newBuffer.deallocate(capacity: bufferLength + 1) }
            memcpy(UnsafeMutableRawPointer(newBuffer), buffer, bufferLength)
            newBuffer[bufferLength] = 0
            string = String(cString: UnsafePointer(newBuffer))
        }
    } else {
        string = ""
    }
    
    return parser.appendString(string)
}

fileprivate func yajl_start_map(_ pointer: UnsafeMutableRawPointer?) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.startMap()
}

fileprivate func yajl_map_key(
    _ pointer: UnsafeMutableRawPointer?,
    buffer: UnsafePointer<UInt8>?,
    bufferLength: Int
) -> Int32 {
    guard let buffer = buffer else {
        return 0
    }
    
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    let string: String
    
    if bufferLength > 0 {
        if bufferLength < parser.bufferCapacity {
            memcpy(UnsafeMutableRawPointer(parser.buffer), UnsafeRawPointer(buffer), bufferLength)
            parser.buffer[bufferLength] = 0
            string = String(cString: UnsafePointer(parser.buffer))
        } else {
            var newBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferLength + 1)
            defer { newBuffer.deallocate(capacity: bufferLength + 1) }
            memcpy(UnsafeMutableRawPointer(newBuffer), buffer, bufferLength)
            newBuffer[bufferLength] = 0
            string = String(cString: UnsafePointer(newBuffer))
        }
    } else {
        string = ""
    }
    
    return parser.mapKey(string)
}

fileprivate func yajl_end_map(_ pointer: UnsafeMutableRawPointer?) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.endMap()
}

fileprivate func yajl_start_array(_ pointer: UnsafeMutableRawPointer?) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.startArray()
}

fileprivate func yajl_end_array(_ pointer: UnsafeMutableRawPointer?) -> Int32 {
    let parser = Unmanaged<JSONParser>.fromOpaque(pointer!).takeUnretainedValue()
    return parser.endArray()
}
