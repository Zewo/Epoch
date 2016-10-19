extension UTF8 {
    public static let whitespaceAndNewline: Set<UTF8.CodeUnit> = UnicodeScalars.whitespaceAndNewline.utf8()
    public static let digits: Set<UTF8.CodeUnit> = UnicodeScalars.digits.utf8()
    public static let uriQueryAllowed: Set<UTF8.CodeUnit> = UnicodeScalars.uriQueryAllowed.utf8()
    public static let uriFragmentAllowed: Set<UTF8.CodeUnit> = UnicodeScalars.uriFragmentAllowed.utf8()
    public static let uriPathAllowed: Set<UTF8.CodeUnit> = UnicodeScalars.uriPathAllowed.utf8()
    public static let uriHostAllowed: Set<UTF8.CodeUnit> = UnicodeScalars.uriHostAllowed.utf8()
    public static let uriPasswordAllowed: Set<UTF8.CodeUnit> = UnicodeScalars.uriPasswordAllowed.utf8()
    public static let uriUserAllowed: Set<UTF8.CodeUnit> = UnicodeScalars.uriUserAllowed.utf8()
}

extension UTF8.CodeUnit {
    func hexadecimal() -> String {
        let hexadecimal =  String(self, radix: 16, uppercase: true)
        return (self < 16 ? "0" : "") + hexadecimal
    }
}
