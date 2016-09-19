import XCTest
@testable import RethinkDB

public class ReqlAstTests : XCTestCase {
    func testSimpleAst() {
        /*
         r.db("blog").table("users").filter({name: "Michel"})
         */

        let expected = "[39,[[15,[[14,[\"blog\"]],\"users\"]],{\"name\":\"Michel\"}]]"
        let compiled = try! r.db("blog").table("users").filter(["name": "Michel"]).compileToReqlJSON()

        XCTAssertEqual(expected, compiled)

    }

    func testComplexAst() {
        /*
         r.do(10, 20, function (x, y) {
         return r.add(x, y);
         })
         */

        let expected = "[64,[[69,[[2,[1,2]],[24,[[10,[1]],[10,[2]]]]]],10,20]]"
        let compiled = try! r.`do`(10, 20, { (x: ReqlExpr, y: ReqlExpr) -> ReqlArg in
            return r.add(x, y)
        }).compileToReqlJSON()

        XCTAssertEqual(expected, compiled)
    }

    func testOptsAst() {
        /*

         r.table("users", {read_mode: "single"});

         */

        let expected = "[15,[\"users\"],{\"read_mode\":\"single\"}]"

        let compiled = try! r.table("users", ReqlTableOpts(readMode: .single)).compileToReqlJSON()

        XCTAssertEqual(expected, compiled)
    }

    func testBacktraceAst() {

        do {
            _ = try r.table("users").filter({ (bad: Data, function: Bool) -> Any in
                return "Hello"
            }).compileToReqlJSON()
        } catch let error as RethinkDB.Error {
            guard case let .reql(backtrace) = error.code, backtrace != nil else {
                XCTFail("Invalid Error Code: \(error.code)")
                return
            }
        } catch {
            XCTFail("Invalid Error Type: \(error.self)")
        }
    }
}

extension ReqlAstTests {
    public static var allTests: [(String, (ReqlAstTests) -> () throws -> Void)] {
        return [
            ("testSimpleAst", testSimpleAst),
            ("testComplexAst", testComplexAst),
            ("testOptsAst", testOptsAst),
            ("testBacktraceAst", testBacktraceAst),
        ]
    }
}
