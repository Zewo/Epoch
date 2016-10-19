// Warning: We're gonna need this when we split Venice from Quark in the future

//extension String {
//    public func split(separator: UnicodeScalar, maxSplits: Int = .max, omittingEmptySubsequences: Bool = true) -> [String] {
//        return unicodeScalars.split(separator: separator, maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences).map(String.init)
//    }
//
//    /// Returns `true` if `self` starts with `prefix`.
//    public func has(prefix: String) -> Bool {
//        guard prefix.unicodeScalars.count <= unicodeScalars.count else { return false }
//
//        let lhs = unicodeScalars.prefix(prefix.unicodeScalars.count)
//        let rhs = prefix.unicodeScalars
//
//        return !zip(lhs, rhs).contains { $0 != $1 }
//    }
//
//    /// Returns `true` if `self` ends with `suffix`.
//    public func has(suffix: String) -> Bool {
//        guard suffix.unicodeScalars.count <= unicodeScalars.count else { return false }
//
//        let lhs = unicodeScalars.suffix(suffix.unicodeScalars.count)
//        let rhs = suffix.unicodeScalars
//
//        return !zip(lhs, rhs).contains { $0 != $1 }
//    }
//}

extension String {
    func droppingLastPathComponent() -> String {
        let string = self.fixingSlashes()

        if string == "/" {
            return string
        }

        switch string.startOfLastPathComponent() {

        // relative path, single component
        case string.unicodeScalars.startIndex:
            return ""

        // absolute path, single component
        case string.unicodeScalars.index(after: string.unicodeScalars.startIndex):
            return "/"

        // all common cases
        case let startOfLast:
            return String(string.unicodeScalars.prefix(upTo: string.unicodeScalars.index(before: startOfLast)))
        }
    }

    func fixingSlashes(mergeRepetitive: Bool = true, stripTrailing: Bool = true) -> String {
        if self == "/" {
            return self
        }

        var result = UnicodeScalarView()

        if mergeRepetitive {
            for scalar in unicodeScalars {
                if scalar != "/" || result.last != "/" {
                    result.append(scalar)
                }
            }
        } else {
            result = unicodeScalars
        }

        if stripTrailing {
            if result.last == "/" {
                result = result.dropLast()
            }
        }

        return String(result)
    }

    func startOfLastPathComponent() -> UnicodeScalarView.Index {
        return unicodeScalars.reversed().index(of: "/")?.base ?? unicodeScalars.startIndex
    }
}
