extension ReqlTable {
    public func config(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .config, args: args, parent: self, file: file, line: line)
    }

    public func get(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .get, args: args, parent: self, file: file, line: line)
    }

    public func getAll(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .getAll, args: args, parent: self, file: file, line: line)
    }

    public func getIntersecting(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .getIntersecting, args: args, parent: self, file: file, line: line)
    }

    public func getNearest(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .getNearest, args: args, parent: self, file: file, line: line)
    }

    public func grant(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .grant, args: args, parent: self, file: file, line: line)
    }

    public func indexCreate(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .indexCreate, args: args, parent: self, file: file, line: line)
    }

    public func indexDrop(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .indexDrop, args: args, parent: self, file: file, line: line)
    }

    public func indexList(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .indexList, args: args, parent: self, file: file, line: line)
    }

    public func indexRename(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .indexRename, args: args, parent: self, file: file, line: line)
    }

    public func indexStatus(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .indexStatus, args: args, parent: self, file: file, line: line)
    }

    public func indexWait(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .indexWait, args: args, parent: self, file: file, line: line)
    }

    public func insert(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .insert, args: args, parent: self, file: file, line: line)
    }

    public func rebalance(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .rebalance, args: args, parent: self, file: file, line: line)
    }

    public func reconfigure(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .reconfigure, args: args, parent: self, file: file, line: line)
    }

    public func status(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .status, args: args, parent: self, file: file, line: line)
    }

    public func sync(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .sync, args: args, parent: self, file: file, line: line)
    }

    public func wait(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .wait, args: args, parent: self, file: file, line: line)
    }
}
