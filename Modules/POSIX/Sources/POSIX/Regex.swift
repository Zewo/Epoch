#if os(Linux)
    @_exported import Glibc
#else
    @_exported import Darwin.C
#endif

import Foundation


public struct RegexError : Error {
    let description: String

    static func error(from result: Int32, preg: regex_t) -> RegexError {
        var preg = preg
        var buffer = [Int8](repeating: 0, count: Int(BUFSIZ))
        regerror(result, &preg, &buffer, buffer.count)
        let description = String(validatingUTF8: buffer)!
        return RegexError(description: description)
    }
}


public final class Regex {

    public struct RegexOptions : OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let basic            = RegexOptions(rawValue: 0)
        public static let extended         = RegexOptions(rawValue: 1)
        public static let caseInsensitive  = RegexOptions(rawValue: 2)
        public static let newLineSensitive = RegexOptions(rawValue: 4)
        public static let resultOnly       = RegexOptions(rawValue: 8)
    }

    public struct MatchOptions : OptionSet {
        public let rawValue: Int32

        public init(rawValue: Int32) {
            self.rawValue = rawValue
        }

        public static let FirstCharacterNotAtBeginningOfLine = MatchOptions(rawValue: REG_NOTBOL)
        public static let LastCharacterNotAtEndOfLine        = MatchOptions(rawValue: REG_NOTEOL)
    }

//    final class GroupIterator : IteratorProtocol {
//        typealias Element = String
//
//        var string: String
//        var preg: regex_t
//        var regexMatches: [regmatch_t]
//        let maxMatches = 10
//        let matchOptions: MatchOptions
//        var groupIdx = 0
//
//        init(string: String, preg: regex_t, matchOptions: MatchOptions) {
//            self.string = string
//            self.preg = preg
//            self.matchOptions = matchOptions
//            self.regexMatches = [regmatch_t](repeating: regmatch_t(), count: maxMatches)
//        }
//
//        func next() -> GroupIterator.Element? {
//            if groupIdx == maxMatches {
//                let result = regexec(&preg, string, regexMatches.count, &regexMatches, matchOptions.rawValue)
//
//                if result != 0 {
//                    return nil
//                }
//
//                groupIdx = 0
//            }
//
//            groupIdx += 1
//
//            /// extract the group if exists
//            let match: String?
//            if regexMatches[groupIdx].rm_so != -1 {
//                let group = (start: regexMatches[groupIdx].rm_so, end: regexMatches[groupIdx].rm_eo)
//                let (startIndex, endIndex) = (index(from: group.start, in: string), index(from: group.end, in: string))
//                match = string[startIndex ..< endIndex]
//            } else {
//                match = nil
//            }
//
//            /// remove all matched part from the string before the next iteration
//            if groupIdx == maxMatches {
//                let indexOfEndOfMatch = index(from: regexMatches[0].rm_eo, in: string)
//                let remainderString = string.substring(with: indexOfEndOfMatch ..< string.endIndex)
//                if !remainderString.isEmpty {
//                    string = remainderString
//                } else {
//
//                }
//            }
//            return match
//        }
//
//        func index(from offset: regoff_t, in string: String) -> String.Index {
//            return string.index(string.startIndex, offsetBy: Int(offset))
//        }
//    }



    var preg = regex_t()

    public init(pattern: String, options: RegexOptions = .extended) throws {
        let result = regcomp(&preg, pattern, options.rawValue)

        if result != 0 {
            throw RegexError.error(from: result, preg: preg)
        }
    }

    deinit {
        regfree(&preg)
    }

    func index(from offset: regoff_t, in utf8view: String.UTF8View) -> String.UTF8View.Index {
        return utf8view.index(utf8view.startIndex, offsetBy: Int(offset))
    }

    public func matches(in string: String, options: MatchOptions = []) -> Bool {
        var regexMatches = [regmatch_t](repeating: regmatch_t(), count: 1)
        let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

        if result != 0 {
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

            if result != 0 {
                break // Unmatched regex
            }

            if regexMatches[0].rm_eo == regexMatches[0].rm_so {
                break // matches the empty string: infinite loop
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

            if !remainderString.isEmpty {
                string = remainderString
            } else {
                break
            }
        }

        return groups
    }

    public func replace(in string: String, with template: String, options: MatchOptions = []) -> String {
        var string = string
        let maxMatches = 10
        var totalReplacedString: String = ""
        let templateArray = [UInt8](template.utf8)

        while true {
            var regexMatches = [regmatch_t](repeating: regmatch_t(), count: maxMatches)
            let result = regexec(&preg, string, regexMatches.count, &regexMatches, options.rawValue)

            if result != 0 {
                break // Unmatched regex
            }

            if regexMatches[0].rm_eo == regexMatches[0].rm_so {
                break // matches the empty string: infinite loop
            }

            let start = Int(regexMatches[0].rm_so)
            let end   = Int(regexMatches[0].rm_eo)
            var replacedStringArray = [UInt8](string.utf8)
            replacedStringArray.replaceSubrange(start..<end, with: templateArray)

            guard let replacedString = String(data: Data(replacedStringArray), encoding: .utf8) else {
                break
            }
//            let replacedString = String(describing: replacedStringArray)

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
    return regex.matches(in: string)
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
