import Foundation

#if os(macOS)
extension NSTextCheckingResult {
    func range(at index: Int) -> NSRange {
        return rangeAt(index)
    }
}
#endif

public enum EnvironmentError : Error {
    case valueNotFound(key: String, variables: [String: String])
    case cannotInitialize(type: LosslessStringConvertible.Type, variable: String)
}

extension EnvironmentError : CustomStringConvertible {
    /// :nodoc:
    public var description: String {
        switch self {
        case let .valueNotFound(key, variables):
            // TODO: pretty print the dictionary, like:
            // key1: value1
            // key2: value2
            // key3: value3
            return "Cannot get variable for key \"\(key)\". Key is not present in variables \(variables)."
        case let .cannotInitialize(type, variable):
            return "Cannot initialize type \"\(String(describing: type))\" with variable \"\(variable)\"."
        }
    }
}

public struct Environment {
    public static var path = ""
    public static var dotEnvEncoding: String.Encoding = .utf8
    
    public static var variables: [String: String] = {
        var variables = ProcessInfo.processInfo.environment
        let filePath = path == "" ? packageDirectory + "/.env" : path
        
        guard let fileHandle = FileHandle(forReadingAtPath: filePath) else {
            return variables
        }

        let data = fileHandle.readDataToEndOfFile()
        
        guard let content = String(data: data, encoding: .utf8) else {
            return variables
        }
        
        for (key, value) in parse(content) {
            variables[key] = value
        }
        
        return variables
    }()
    
    public static func variable(_ key: String) throws -> String {
        guard let variable = variables[key] else {
            throw EnvironmentError.valueNotFound(key: key, variables: variables)
        }
        
        return variable
    }
    
    public static func variable<V : LosslessStringConvertible>(_ key: String) throws -> V {
        let string = try variable(key)
        
        guard let variable = V(string) else {
            throw EnvironmentError.cannotInitialize(type: V.self, variable: string)
        }
        
        return variable
    }
    
    static func parse(_ content: String) -> [String: String] {
        var variables: [String: String] = [:]
        
        let regex = try! NSRegularExpression(
            pattern: "^\\s*([\\w\\.\\-]+)\\s*=\\s*(.*)?\\s*$",
            options: []
        )
        
        for line in content.components(separatedBy: "\n") {
            let string = NSString(string: line)
            
            let matches = regex.matches(
                in: line,
                options: [],
                range: NSRange(location: 0, length: string.length)
            )
            
            guard let match = matches.first else {
                continue
            }
            
            guard let keyRange = match.range(at: 1).range(for: line) else {
                continue
            }
            
            let key = line.substring(with: keyRange)
            var value = ""
            
            if
                match.numberOfRanges == 3,
                let valueRange = match.range(at: 2).range(for: line)
            {
                value = line.substring(with: valueRange)
            }
            
            value = value.trimmingCharacters(in: .whitespaces)
            
            if
                value.characters.count > 1,
                value.characters.first == "\"",
                value.characters.last == "\""
            {
                value = value.replacingOccurrences(
                    of: "\\n",
                    with: "\n"
                )
                
                value.characters.removeFirst()
                value.characters.removeLast()
            }
            
            variables[key] = value
        }
        
        return variables
    }
    
    public static var packageDirectory: String {
        if #file.contains(".build") {
            return #file.components(separatedBy: "/.build").first ?? System.workingDirectory
        }
        
        if #file.contains("Packages") {
            return #file.components(separatedBy: "/Packages").first ?? System.workingDirectory
        }
        
        return #file.components(separatedBy: "/Sources").first ?? System.workingDirectory
    }
}

extension NSRange {
    func range(for str: String) -> Range<String.Index>? {
        guard location != NSNotFound else { return nil }
        
        guard let fromUTFIndex = str.utf16.index(str.utf16.startIndex, offsetBy: location, limitedBy: str.utf16.endIndex) else { return nil }
        guard let toUTFIndex = str.utf16.index(fromUTFIndex, offsetBy: length, limitedBy: str.utf16.endIndex) else { return nil }
        guard let fromIndex = String.Index(fromUTFIndex, within: str) else { return nil }
        guard let toIndex = String.Index(toUTFIndex, within: str) else { return nil }
        
        return fromIndex ..< toIndex
    }
}
