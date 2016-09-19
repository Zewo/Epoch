extension ReqlDb {
    public func config(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .config, args: args, parent: self, file: file, line: line)
    }

    public func grant(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .grant, args: args, parent: self, file: file, line: line)
    }

    public func rebalance(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .rebalance, args: args, parent: self, file: file, line: line)
    }

    public func reconfigure(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .reconfigure, args: args, parent: self, file: file, line: line)
    }

    public func table(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlTable {
        return ReqlTable(term: .table, args: args, parent: self, file: file, line: line)
    }

    public func tableCreate(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .tableCreate, args: args, parent: self, file: file, line: line)
    }

    public func tableDrop(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .tableDrop, args: args, parent: self, file: file, line: line)
    }

    public func tableList(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .tableList, args: args, parent: self, file: file, line: line)
    }

    public func wait(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .wait, args: args, parent: self, file: file, line: line)
    }
}
