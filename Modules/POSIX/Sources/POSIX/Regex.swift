#if os(Linux)
    import Glibc
#else
    import Darwin.C
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

    /// Constructs a Regex using the given string pattern and `RegexOptions`.
    ///
    /// - parameter pattern: string holding the Regex pattern.
    /// - parameter options: Options such as `Regex.Options.basic` (BRE) or `Regex.Options.extended` (ERE).
    ///
    /// - throws: `RegexError` if the given pattern is not a valid Regex.
    public init(_ pattern: String, options: Options = .extended) throws {
        let result = regcomp(&preg, pattern, options.rawValue)

        guard result == 0 else {
            throw RegexError.error(from: result, preg: &preg)
        }
    }

    deinit {
        regfree(&preg)
    }

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
fileprivate func utf8Index(from offset: regoff_t, in utf8view: String.UTF8View) -> String.UTF8View.Index {
    return utf8view.index(utf8view.startIndex, offsetBy: Int(offset))
}


extension String {

    /// Check if the string matches a given Regex Regular Expression.
    ///
    /// - parameter regex: Regex regular expression.
    /// - parameter options: Matching options like `firstCharacterNotAtBeginningOfLine` (`REG_NOTBOL` in POSIX parlance).
    ///
    /// - returns: `true` if the string matches the regex, else `false`.
    public func matches(_ regex: Regex, options: Regex.MatchOptions = []) -> Bool {
        
        var regexMatches = [regmatch_t](repeating: regmatch_t(), count: 1)
        let result = regexec(&(regex.preg), self, regexMatches.count, &regexMatches, options.rawValue)

        guard result == 0 else {
            return false
        }
        
        return true
    }

    /// Check if the string matches a given Regular Expression pattern string.
    ///
    /// - parameter pattern: Regular Expression pattern string, like `[[:digit:]]{4,}`.
    /// - parameter options: Matching options like `firstCharacterNotAtBeginningOfLine` (`REG_NOTBOL` in POSIX parlance).
    ///
    /// - throws: `RegexError` indicating why the given pattern string cannot be used to construct a valid Regex Regular Expression.
    ///
    /// - returns: `true` if the string matches the regex, else `false`.
    public func matches(_ pattern: String, options: Regex.MatchOptions = []) throws -> Bool {
        let regex = try Regex(pattern)
        return self.matches(regex, options: options)
    }

    
    /// Substrings matching a given Regex Regular Expression.
    ///
    /// - parameter regex: Regex regular expression.
    /// - parameter options: Matching options like `firstCharacterNotAtBeginningOfLine` (`REG_NOTBOL` in POSIX parlance).
    ///
    /// - returns: Matching substrings.
    public func groupsMatching(_ regex: Regex, options: Regex.MatchOptions = []) -> [String] {

        var string = self
        let maxMatches = 10
        var groups = [String]()
        var regexMatches = [regmatch_t](repeating: regmatch_t(), count: maxMatches)

        // Iterate over the string per batch of 10 matches
        while true {
            let result = regexec(&(regex.preg), string, regexMatches.count, &regexMatches, options.rawValue)

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
                let startIndexUTF8 = utf8Index(from: group.start, in: string.utf8)
                let endIndexUTF8 = utf8Index(from: group.end, in: string.utf8)

                let match = String(string.utf8[startIndexUTF8..<endIndexUTF8])!
                groups.append(match)
                groupIdx += 1
            }

            let indexOfEndOfMatchUTF8 = utf8Index(from: regexMatches[0].rm_eo, in: string.utf8)
            let remainderString = String(string.utf8[indexOfEndOfMatchUTF8..<string.utf8.endIndex])!

            guard remainderString.isEmpty else {
                break
            }
            string = remainderString
            
        }

        return groups
    }
    
    /// Substrings matching a given Regular Expression pattern string.
    ///
    /// - parameter pattern: Regular Expression pattern string, like `([[:digit:]]{4,})`.
    /// - parameter options: Matching options like `firstCharacterNotAtBeginningOfLine` (`REG_NOTBOL` in POSIX parlance).
    ///
    /// - throws: `RegexError` indicating why the given pattern string cannot be used to construct a valid Regex Regular Expression.
    ///
    /// - returns: Matching substrings.
    public func groupsMatching(_ pattern: String, options: Regex.MatchOptions = []) throws -> [String] {
        let regex = try Regex(pattern)
        return self.groupsMatching(regex, options: options)
    }

    
    /// Return a new string in which substrings matching a given Regex Regular Expression were replaced with the given template string.
    ///
    /// - parameter regex: Regex Regular Expression.
    /// - parameter template: String used to replace all substrings matching the Regular Expression.
    /// - parameter options:  Matching options like `firstCharacterNotAtBeginningOfLine` (`REG_NOTBOL` in POSIX parlance).
    ///
    /// - returns: New string in which all substrings matching the regex were replaced with the template.
    public func replace(_ regex: Regex, with template: String, options: Regex.MatchOptions = []) -> String {
        
        var string = self
        let maxMatches = 10
        var totalReplacedString: String = ""
        let templateArray = [UInt8](template.utf8)
        
        while true {
            var regexMatches = [regmatch_t](repeating: regmatch_t(), count: maxMatches)
            let result = regexec(&(regex.preg), string, regexMatches.count, &regexMatches, options.rawValue)

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
    
    /// Return a new string in which substrings matching a given Regular Expression pattern string were replaced with the given template string.
    ///
    /// - parameter pattern: Regular Expression pattern string, like `[[:digit:]]{4,}`.
    /// - parameter template: String used to replace all substrings matching the Regular Expression.
    /// - parameter options:  Matching options like `firstCharacterNotAtBeginningOfLine` (`REG_NOTBOL` in POSIX parlance).
    ///
    /// - returns: New string in which all substrings matching the regex were replaced with the template.
    public func replace(_ pattern: String, with template: String, options: Regex.MatchOptions = []) throws -> String {
        let regex = try Regex(pattern)
        return self.replace(regex, with: template, options: options)
    }
}



// MARK: - Helper for building Regex Regular Expression from string literal.
//
// Warning: Errors will not be caught if the given string literal cannot yield a valid Regular Expression
//
// Example usage: `let regex: Regex = "[[:digit:]]{4,}"`
//
extension Regex : ExpressibleByStringLiteral {
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType

    public convenience init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        try! self.init(value, options: .extended)
    }

    public convenience init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        try! self.init(value, options: .extended)
    }

    public convenience init(stringLiteral value: StringLiteralType) {
        try! self.init(value, options: .extended)
    }
}


/// MARK: - Operators


/// Check if a string matches a given Regex.
///
/// - parameter string: String to match.
/// - parameter regex:  Regex to use for matching.
///
/// - returns: `true` if the given string matches the Regex, else `false`.
public func ~ (string: String, regex: Regex) -> Bool {
    return string.matches(regex)
}

/// Check if a string matches a given regex pattern.
///
/// - parameter string:  String to match.
/// - parameter pattern: String holding the regex pattern.
///
/// - throws: `RegexError` if the given regex pattern as not a valid Regex.
///
/// - returns: `true` if the given string matches the regex pattern, else `false`.
public func ~ (string: String, pattern: String) throws -> Bool {
    let regex = try Regex(pattern)
    return string ~ regex
}

/// Check if a string matches a given regex pattern.
///
/// - note: returns `nil` instead of throwing if the given regex pattern as not a valid Regex.
///
/// - parameter string:  String to match.
/// - parameter pattern: String holding the regex pattern.
///
/// - returns: `true` if the given string matches the regex pattern, else `false`.
public func ~? (string: String, pattern: String) -> Bool? {
    return try? (string ~ pattern)
}


/// Matching groups in a string, given a regex pattern.
///
/// This function throws if a valid regex cannot be built out of the given pattern.
///
/// - parameter string:  String in which to search for groups.
/// - parameter pattern: String pattern to use as a regex.
///
/// - throws: `RegexError` indicating why the given pattern is not a valid Regex.
///
/// - returns: Matching groups as an array of strings
public func ~* (string: String, pattern: String) throws -> [String] {
    let regex = try Regex(pattern)
    return string ~* regex
}

/// Matching groups in a string, given a Regex.
///
/// - parameter string: String in which to search for groups.
/// - parameter regex:  String pattern to use as a regex.
///
/// - returns: Matching groups as an array of strings
public func ~* (string: String, regex: Regex) -> [String] {
    return string.groupsMatching(regex)
}

/// Matching groups in a string, given a regex pattern.
///
/// - note: returns `nil` instead of throwing if the given regex pattern as not a valid Regex.
///
/// - parameter string:  String in which to search for groups.
/// - parameter pattern: String pattern to use as a regex.
///
/// - returns: Matching groups as an array of strings, or `nil` if the given pattern is not a valid Regex.
public func ~*? (string: String, pattern: String) -> [String]? {
    guard let regex = try? Regex(pattern) else {
        return nil
    }
    return string ~* regex
}


infix operator ~
infix operator ~?
infix operator ~*
infix operator ~*?
