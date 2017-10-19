import XCTest
@testable import Media

public class JSONTests : XCTestCase {
    func testJSONSchema() throws {
        let schema = JSON.Schema([
            "type": "object",
            "properties": [
                "name": ["type": "string"],
                "price": ["type": "number"],
            ],
            "required": ["name"],
        ])
        
        var result = schema.validate(["name": "Eggs", "price": 34.99])
        XCTAssert(result.isValid)
        
        result = schema.validate(["price": 34.99])
        XCTAssertEqual(result.errors, ["Required properties are missing '[\"name\"]\'"])
    }
    
    func testSerialize() throws {
        let json: JSON = ["string": "string", "int": 1, "bool": true, "nil": nil, "array":["a": 1, "b": 2], "object": ["c": "d", "e": "f"], "intarray": [1, 2, 3, 5]]
        
        var s: String?
        try JSONSerializer().serialize(json) { (buf) in
            s = String(buf)
        }
        
        XCTAssertEqual("{\"nil\":null,\"intarray\":[1,2,3,5],\"object\":{\"e\":\"f\",\"c\":\"d\"},\"array\":{\"b\":2,\"a\":1},\"int\":1,\"bool\":true,\"string\":\"string\"}", s)
    }
}

extension JSONTests {
    public static var allTests: [(String, (JSONTests) -> () throws -> Void)] {
        return [
            ("testJSONSchema", testJSONSchema),
        ]
    }
}
