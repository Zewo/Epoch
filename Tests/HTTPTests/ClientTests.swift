import XCTest
import Content
import HTTP

public class ClientTests: XCTestCase {
    func testClient() throws {
        do {
            let client = try Client(uri: "https://api.github.com")
            let request = try Request(method: .get, uri: "/zen")
            let response = try client.send(request)
            let zen: PlainText = try response.content()
            print(zen)
        } catch {
            print(error)
        }
    }
}

extension ClientTests {
    public static var allTests: [(String, (ClientTests) -> () throws -> Void)] {
        return [
            ("testClient", testClient),
        ]
    }
}
