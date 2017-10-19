import XCTest
import Foundation
@testable import Media

struct User : Codable {
    let string: String
    let int: Int
    let bool: Bool
    let double: Double?
    let null: String?
}

struct Organization: Codable {
    let name: String
    let departments: [Department]
}

struct Department: Codable {
    let name: String
    let workers: [User]
    let manager: User
}

class MapperTests : XCTestCase {
    func testDecodeObject() throws {
        let json: JSON = ["string": "Paulo", "double": 0.1, "int": 100, "bool": true, "null": nil]
        
        let user = try User(from: json)
        
        XCTAssertEqual(user.string, "Paulo")
        XCTAssertEqual(user.int, 100)
        XCTAssertEqual(user.bool, true)
        XCTAssertEqual(user.double, 0.1)
        XCTAssertNil(user.null)
    }
    
    func testDecodeArrayOfObjects() throws {
        let json: JSON = [["string": "Paulo0", "double": 0.1, "int": 100, "bool": true, "null": nil], ["string": "Paulo1", "double": 1.1, "int": 101, "bool": true, "null": nil]]
        
        let users = try [User](from: json)
        
        var i = 0
        for user in users {
            XCTAssertEqual(user.string, "Paulo\(i)")
            XCTAssertEqual(user.int, 100 + i)
            XCTAssertEqual(user.bool, true)
            XCTAssertEqual(user.double, 0.1 + Double(i))
            XCTAssertNil(user.null)
            i += 1
        }
    }
    
    func testDecodeArrayWithNil() throws {
        let input = [1, nil, 3, nil]
        let json: JSON = [1, nil, 3, nil]
        let output = try [Int?](from: json)
        
        for i in 0 ..< input.count {
            XCTAssertEqual(input[i], output[i])
        }
    }

    func testDecodeSingleValue() throws {
        let json: JSON = 1
        let result = try Int(from: json)
        
        XCTAssertEqual(result, 1)
    }

    func testDecodeSingleNil() throws {
        let json: JSON = JSON.null
        let result = try Int?(from: json)
        
        XCTAssertNil(result)
    }

    func testDecodeHierarchy() throws {
        let json: JSON = ["name": "organization",
                          "departments": [
                            ["name": "department",
                             "manager": ["string": "Paulo", "double": 0.1, "int": 100, "bool": true, "null": nil],
                             "workers": [
                                ["string": "Paulo", "double": 0.1, "int": 100, "bool": true, "null": nil]
                              ]
                            ]
                           ]
                          ]

        let result = try Organization(from: json)
        print(result)
    }
    
//    func testEncodeObject() throws {
//        let user = User(string: "test", int: 1, bool: true, double: 0.1, null: nil)
//        
//        let json = try JSON(from: user)
//        
//        print(json)
//    }
}
