public struct ReqlConfig {
    let connect: (() throws -> Transport)
    let db: String
    let username: String
    let password: String

    init(connect: @escaping (() throws -> Transport),
         db: String = "test",
         username: String = "admin",
         password: String = "") {
        self.connect = connect
        self.db = db
        self.username = username
        self.password = password
    }
}
