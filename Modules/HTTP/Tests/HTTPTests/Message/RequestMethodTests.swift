import XCTest
@testable import HTTP

let requestMethod: [Request.Method: String] = [
    .delete: "DELETE",
    .get: "GET",
    .head: "HEAD",
    .post: "POST",
    .put: "PUT",
    .connect: "CONNECT",
    .options: "OPTIONS",
    .trace: "TRACE",
    .patch: "PATCH",
    .other(method: "open"): ("OPEN"),
]

public class RequestMethodTests : XCTestCase {
    func testMethod() throws {
        for (method, rawMethod) in requestMethod {
            XCTAssertEqual(method, method)
            XCTAssertEqual(method.description, rawMethod)
            let newMethod = Request.Method(rawMethod)
            XCTAssertEqual(newMethod, method)
        }
    }
}

extension RequestMethodTests {
    public static var allTests: [(String, (RequestMethodTests) -> () throws -> Void)] {
        return [
            ("testMethod", testMethod),
        ]
    }
}
