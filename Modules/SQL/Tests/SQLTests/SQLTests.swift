import XCTest
@testable import SQL

struct User {
    let username: String
    let password: String
}

extension User: ModelProtocol {
    typealias PrimaryKey = Int

    enum Field: String, ModelField {
        case username
        case password
        case id

        static let tableName: String = "users"
        static let primaryKey: Field = .id
    }

    func serialize() -> [Field : ValueConvertible?] {
        return [
            .username: username,
            .password: password
        ]
    }

    init<Row: RowProtocol>(row: TableRow<User, Row>) throws {
        username = try row.value(.username)
        password = try row.value(.password)
    }
}


public class SQLTests: XCTestCase {
    //TODO: Add tests
    func testSelectQuery() {
        User.select(where: User.Field.id == 1)
    }
}

extension SQLTests {
    public static var allTests: [(String, (SQLTests) -> () throws -> Void)] {
        return [
            ("testSelectQuery", testSelectQuery),
        ]
    }
}
