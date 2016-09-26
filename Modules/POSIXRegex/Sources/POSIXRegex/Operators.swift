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
