public class ReqlExpr : ReqlAst {
    public subscript(key: Any) -> ReqlExpr {
        return self.bracket(key)
    }
}
