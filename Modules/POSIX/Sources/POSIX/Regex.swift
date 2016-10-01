#if os(Linux)
    @_exported import Glibc
#else
    @_exported import Darwin.C
#endif

import Foundation


public struct RegexError : Error {
    let description: String

    static func error(from result: Int32, preg: inout regex_t) -> RegexError {
        var buffer = [Int8](repeating: 0, count: Int(BUFSIZ))
        regerror(result, &preg, &buffer, buffer.count)
        let description = String(cString: buffer)
        return RegexError(description: description)
    }
}


public final class Regex {

    public struct Options : OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let basic            = Options(rawValue: 0)
        public static let extended         = Options(rawValue: 1)
        public static let caseInsensitive  = Options(rawValue: 2)
        public static let newLineSensitive = Options(rawValue: 4)
        public static let resultOnly       = Options(rawValue: 8)
    }

    public struct MatchOptions : OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let firstCharacterNotAtBeginningOfLine = MatchOptions(rawValue: REG_NOTBOL)
        public static let lastCharacterNotAtEndOfLine        = MatchOptions(rawValue: REG_NOTEOL)
    }


    var preg = regex_t()

    public init(pattern: String, options: Options = .extended) throws {
        let result = regcomp(&preg, pattern, options.rawValue)

        guard result == 0 else {
            throw RegexError.error(from: result, preg: &preg)
        }
    }

    deinit {
        regfree(&preg)
    }

    /// In the context of a String UTF8View, returns the UTF8View.Index
    /// of a given character (designated by `regoff`)
    /// 
    /// Helper that simplifies the code written at the call site.
    ///
    /// - parameter offset:   Offset to a char (returned by native `regexec()`).
    /// - parameter utf8view: UTF8View of the string.
    ///
    /// - returns: UTF8View.Index of the character designated by `regoff`.
    func index(from offset: regoff_t, in utf8view: String.UTF8View) -> String.UTF8View.Index {
        return utf8view.index(utf8view.startIndex, offsetBy: Int(offset))
    }

    public func matches(_ string: String, options: MatchOptions = []) -> Bool {
        var regexMatches = [regmatch_t](repeating: regmatch_t(), count: 1)
        let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

        guard result == 0 else {
            return false
        }
        
        return true
    }

    public func groups(in string: String, options: MatchOptions = []) -> [String] {
        var string = string
        let maxMatches = 10
        var groups = [String]()
        var regexMatches = [regmatch_t](repeating: regmatch_t(), count: maxMatches)

        // Iterate over the string per batch of 10 matches
        while true {
            let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

            guard result == 0 else {
                break // Unmatched regex
            }

            guard regexMatches[0].rm_eo != regexMatches[0].rm_so else {
                break // matches the empty string: avoid infinite loop
            }

            var groupIdx = 1

            // Iterate over the matches
            while regexMatches[groupIdx].rm_so != -1 {
                let group = (start: regexMatches[groupIdx].rm_so, end: regexMatches[groupIdx].rm_eo)

                // Use UTF8View for unicode regexes
                let startIndexUTF8 = index(from: group.start, in: string.utf8)
                let endIndexUTF8 = index(from: group.end, in: string.utf8)

                let match = String(string.utf8[startIndexUTF8..<endIndexUTF8])!
                groups.append(match)
                groupIdx += 1
            }

            let indexOfEndOfMatchUTF8 = index(from: regexMatches[0].rm_eo, in: string.utf8)
            let remainderString = String(string.utf8[indexOfEndOfMatchUTF8..<string.utf8.endIndex])!

            guard remainderString.isEmpty else {
                break
            }
            string = remainderString
            
        }

        return groups
    }

    public func replace(with template: String, in string: String, options: MatchOptions = []) -> String {
        var string = string
        let maxMatches = 10
        var totalReplacedString: String = ""
        let templateArray = [UInt8](template.utf8)

        while true {
            var regexMatches = [regmatch_t](repeating: regmatch_t(), count: maxMatches)
            let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

            guard result == 0 else {
                break // Unmatched regex
            }

            guard regexMatches[0].rm_eo != regexMatches[0].rm_so else {
                break // matches the empty string: avoid infinite loop
            }

            let start = Int(regexMatches[0].rm_so)
            let end   = Int(regexMatches[0].rm_eo)
            var replacedStringArray = [UInt8](string.utf8)
            replacedStringArray.replaceSubrange(start..<end, with: templateArray)
            
            guard let replacedString = String(bytes: replacedStringArray, encoding: .utf8) else {
                break
            }

            let templateDelta = template.utf8.count - (end - start)
            let offset = Int(end + templateDelta)
            let templateDeltaIndex = replacedString.utf8.index(replacedString.utf8.startIndex, offsetBy: offset)

            totalReplacedString += String(describing: replacedString.utf8[replacedString.utf8.startIndex ..< templateDeltaIndex])
            let startIndex = string.utf8.index(string.utf8.startIndex, offsetBy: end)
            string = String(describing: string.utf8[startIndex ..< string.utf8.endIndex])
        }

        return totalReplacedString + string
    }
}


/*
extension Regex : ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

    public convenience init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        try! self.init(pattern: value, options: .extended)
    }

    public convenience init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        try! self.init(pattern: value, options: .extended)
    }

    public convenience init(stringLiteral value: StringLiteralType) {
        try! self.init(pattern: value, options: .extended)
    }
}
*/

/// MARK: - Operators

/// MARK: - matches -> Bool

public func ~ (string: String, regex: Regex) -> Bool {
    return regex.matches(string)
}

public func ~ (string: String, pattern: String) throws -> Bool {
    let regex = try Regex(pattern: pattern)
    return string ~ regex
}

public func ~? (string: String, pattern: String) -> Bool? {
    return try? (string ~ pattern)
}


/// MARK: - group matching (string ~ pattern) -> [String]
///
/// throwing functions (pattern is given as a String)
/// non-throwing functions (pattern is given as a Regex)

public func ~* (string: String, pattern: String) throws -> [String] {
    let regex = try Regex(pattern: pattern)
    return string ~* regex
}

public func ~* (string: String, regex: Regex) -> [String] {
    return regex.groups(in: string)
}

// FIXME: let's talk about this
//func ~* <Result> (left: String, right: String) throws -> ((String) -> Result) -> [Result] {
//    let matchResults = try left ~* right
//
//    return { (f: (String) -> Result) -> [Result] in
//        return matchResults.map(f)
//    }
//}
//
//func ~* <Result> (left: String, right: Regex) -> ((String) -> Result) -> [Result] {
//    let matchResults = left ~* right
//
//    return { (f: (String) -> Result) -> [Result] in
//        return matchResults.map(f)
//    }
//}


//: optional functions

public func ~*? (left: String, right: String) -> [String]? {
    guard let regex = try? Regex(pattern: right) else {
        return nil
    }
    return left ~* regex
}

infix operator ~
infix operator ~?
infix operator ~*
infix operator ~*?
