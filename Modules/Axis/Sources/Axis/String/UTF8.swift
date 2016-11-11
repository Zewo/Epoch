extension UTF8.CodeUnit {
    func hexadecimal() -> String {
        let hexadecimal =  String(self, radix: 16, uppercase: true)
        return (self < 16 ? "0" : "") + hexadecimal
    }
}
