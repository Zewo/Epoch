import Foundation

public typealias ReqlFunction0  = () -> ReqlArg
public typealias ReqlFunction1  = (ReqlExpr) -> ReqlArg
public typealias ReqlFunction2  = (ReqlExpr, ReqlExpr) -> ReqlArg
public typealias ReqlFunction3  = (ReqlExpr, ReqlExpr, ReqlExpr) -> ReqlArg
public typealias ReqlFunction4  = (ReqlExpr, ReqlExpr, ReqlExpr, ReqlExpr) -> ReqlArg
public typealias ReqlFunction5  = (ReqlExpr, ReqlExpr, ReqlExpr, ReqlExpr, ReqlExpr) -> ReqlArg

internal class ReqlFunction: ReqlAst {
    convenience init?(_ f: Any, file: String = #file, line: Int = #line) {
        if let f = f as? ReqlFunction0 {
            self.init(func: f, file: file, line: line)
        } else if let f = f as? ReqlFunction1 {
            self.init(func: f, file: file, line: line)
        } else if let f = f as? ReqlFunction2 {
            self.init(func: f, file: file, line: line)
        } else if let f = f as? ReqlFunction3 {
            self.init(func: f, file: file, line: line)
        } else if let f = f as? ReqlFunction4 {
            self.init(func: f, file: file, line: line)
        } else if let f = f as? ReqlFunction5 {
            self.init(func: f, file: file, line: line)
        } else {
            return nil
        }
    }

    convenience init(func: ReqlFunction0, file: String = #file, line: Int = #line) {
        let result = `func`()
        self.init(term: .`func`, args: [result], parent: nil, file: file, line: line)
    }

    convenience init(func: ReqlFunction1, file: String = #file, line: Int = #line) {
        let vars = [
            ReqlExpr(term: .`var`, args: [1], parent: nil)
        ]
        let result = `func`(vars[0])
        self.init(term: .`func`, args: [[1], result], parent: nil, file: file, line: line)
    }

    convenience init(func: ReqlFunction2, file: String = #file, line: Int = #line) {
        let vars = [
            ReqlExpr(term: .`var`, args: [1], parent: nil),
            ReqlExpr(term: .`var`, args: [2], parent: nil),
            ]
        let result = `func`(vars[0], vars[1])
        self.init(term: .`func`, args: [[1, 2], result], parent: nil, file: file, line: line)
    }

    convenience init(func: ReqlFunction3, file: String = #file, line: Int = #line) {
        let vars = [
            ReqlExpr(term: .`var`, args: [1], parent: nil),
            ReqlExpr(term: .`var`, args: [2], parent: nil),
            ReqlExpr(term: .`var`, args: [3], parent: nil),
            ]
        let result = `func`(vars[0], vars[1], vars[2])
        self.init(term: .`func`, args: [[1, 2, 3], result], parent: nil, file: file, line: line)
    }

    convenience init(func: ReqlFunction4, file: String = #file, line: Int = #line) {
        let vars = [
            ReqlExpr(term: .`var`, args: [1], parent: nil),
            ReqlExpr(term: .`var`, args: [2], parent: nil),
            ReqlExpr(term: .`var`, args: [3], parent: nil),
            ReqlExpr(term: .`var`, args: [4], parent: nil),
            ]
        let result = `func`(vars[0], vars[1], vars[2], vars[3])
        self.init(term: .`func`, args: [[1, 2, 3, 4], result], parent: nil, file: file, line: line)
    }

    convenience init(func: ReqlFunction5, file: String = #file, line: Int = #line) {
        let vars = [
            ReqlExpr(term: .`var`, args: [1], parent: nil),
            ReqlExpr(term: .`var`, args: [2], parent: nil),
            ReqlExpr(term: .`var`, args: [3], parent: nil),
            ReqlExpr(term: .`var`, args: [4], parent: nil),
            ReqlExpr(term: .`var`, args: [5], parent: nil),
            ]
        let result = `func`(vars[0], vars[1], vars[2], vars[3], vars[4])
        self.init(term: .`func`, args: [[1, 2, 3, 4, 5], result], parent: nil, file: file, line: line)
    }
}
