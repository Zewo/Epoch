extension Sequence where Iterator.Element == UTF8.CodeUnit {
    /// Decodes `self` into `String.UnicodeScalarView` using standard `UTF8` decoder.
    ///
    /// - throws: `StringError.invalidUTF8` if the decoding fails with an error.
    func decodeUTF8() throws -> String.UnicodeScalarView {
        var reader = makeIterator()
        var decoder = UTF8()
        var result = String.UnicodeScalarView()
        
        decoding: while true {
            switch decoder.decode(&reader) {
            case .scalarValue(let nextScalar):
                result.append(nextScalar)
            case .emptyInput:
                break decoding
            case .error:
                throw StringError.invalidUTF8
            }
        }

        return result
    }
}
