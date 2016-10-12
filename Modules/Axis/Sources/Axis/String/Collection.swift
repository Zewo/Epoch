extension Collection where Iterator.Element: Equatable, Iterator.Element == SubSequence.Iterator.Element {
    func index(of part: Self) -> Index? {
        guard count >= part.count else { return nil }

        let _offset = stride(from: 0, through: count - part.count, by: 1).first {
            let start = index(startIndex, offsetBy: $0)
            let end = index(start, offsetBy: part.count)
            let counterpart = self[start..<end]
            return !zip(part, counterpart).contains { $0 != $1 }
        }

        guard let offset = _offset else { return nil }

        return index(startIndex, offsetBy: offset)
    }
}
