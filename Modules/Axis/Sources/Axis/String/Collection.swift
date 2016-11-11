extension Collection where Iterator.Element: Equatable, Iterator.Element == SubSequence.Iterator.Element {
    /// Returns the first index where the specified `subcollection` appears in the collection.
    ///
    /// - parameter subcollection: A subcollection to search for within `self`.
    ///
    /// - returns: The first index where `subcollection` is found. If it is not found, returns `nil`.
    func index(of subcollection: Self) -> Index? {
        guard count >= subcollection.count else { return nil }

        let _offset = stride(from: 0, through: count - subcollection.count, by: 1).first(where: { position in
            let counterpartStart = index(startIndex, offsetBy: position)
            let counterpartEnd = index(counterpartStart, offsetBy: subcollection.count)
            let counterpart = self[counterpartStart..<counterpartEnd]
            return !zip(subcollection, counterpart).contains { $0 != $1 }
        })

        guard let offset = _offset else { return nil }

        return index(startIndex, offsetBy: offset)
    }
}
