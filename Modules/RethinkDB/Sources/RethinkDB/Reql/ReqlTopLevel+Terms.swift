extension ReqlTopLevel {
    public static func add(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .add, args: args, parent: nil, file: file, line: line)
    }

    public static func and(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .and, args: args, parent: nil, file: file, line: line)
    }

    public static func april(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .april, args: [], parent: nil, file: file, line: line)
    }

    public static func args(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .args, args: args, parent: nil, file: file, line: line)
    }

    public static func asc(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .asc, args: args, parent: nil, file: file, line: line)
    }

    public static func august(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .august, args: [], parent: nil, file: file, line: line)
    }

    public static func avg(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .avg, args: args, parent: nil, file: file, line: line)
    }

    public static func binary(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .binary, args: args, parent: nil, file: file, line: line)
    }

    public static func branch(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .branch, args: args, parent: nil, file: file, line: line)
    }

    public static func ceil(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ceil, args: args, parent: nil, file: file, line: line)
    }

    public static func circle(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .circle, args: args, parent: nil, file: file, line: line)
    }

    public static func contains(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .contains, args: args, parent: nil, file: file, line: line)
    }

    public static func count(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .count, args: args, parent: nil, file: file, line: line)
    }

    public static func db(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlDb {
        return ReqlDb(term: .db, args: args, parent: nil, file: file, line: line)
    }

    public static func dbCreate(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .dbCreate, args: args, parent: nil, file: file, line: line)
    }

    public static func dbDrop(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .dbDrop, args: args, parent: nil, file: file, line: line)
    }

    public static func dbList(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .dbList, args: [], parent: nil, file: file, line: line)
    }

    public static func december(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .december, args: [], parent: nil, file: file, line: line)
    }

    public static func desc(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .desc, args: args, parent: nil, file: file, line: line)
    }

    public static func distance(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .distance, args: args, parent: nil, file: file, line: line)
    }

    public static func distinct(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .distinct, args: args, parent: nil, file: file, line: line)
    }

    public static func div(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .div, args: args, parent: nil, file: file, line: line)
    }

    public static func epochTime(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .epochTime, args: args, parent: nil, file: file, line: line)
    }

    public static func eq(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .eq, args: args, parent: nil, file: file, line: line)
    }

    public static func error(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .error, args: args, parent: nil, file: file, line: line)
    }

    public static func february(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .february, args: [], parent: nil, file: file, line: line)
    }

    public static func floor(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .floor, args: args, parent: nil, file: file, line: line)
    }

    public static func fold(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .fold, args: args, parent: nil, file: file, line: line)
    }

    public static func friday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .friday, args: [], parent: nil, file: file, line: line)
    }

    public static func funcall(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .funcall, args: args, parent: nil, file: file, line: line)
    }

    public static func `do`(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .funcall, args: args, parent: nil, file: file, line: line)
    }

    public static func ge(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ge, args: args, parent: nil, file: file, line: line)
    }

    public static func geojson(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .geojson, args: args, parent: nil, file: file, line: line)
    }

    public static func grant(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .grant, args: args, parent: nil, file: file, line: line)
    }

    public static func group(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .group, args: args, parent: nil, file: file, line: line)
    }

    public static func gt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .gt, args: args, parent: nil, file: file, line: line)
    }

    public static func http(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .http, args: args, parent: nil, file: file, line: line)
    }

    public static func implicitVar(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .implicitVar, args: [], parent: nil, file: file, line: line)
    }

    public static func row(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .implicitVar, args: [], parent: nil, file: file, line: line)
    }

    public static func info(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .info, args: args, parent: nil, file: file, line: line)
    }

    public static func intersects(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .intersects, args: args, parent: nil, file: file, line: line)
    }

    public static func iso8601(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .iso8601, args: args, parent: nil, file: file, line: line)
    }

    public static func january(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .january, args: [], parent: nil, file: file, line: line)
    }

    public static func javascript(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .javascript, args: args, parent: nil, file: file, line: line)
    }

    public static func js(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .javascript, args: args, parent: nil, file: file, line: line)
    }

    public static func json(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .json, args: args, parent: nil, file: file, line: line)
    }

    public static func july(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .july, args: [], parent: nil, file: file, line: line)
    }

    public static func june(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .june, args: [], parent: nil, file: file, line: line)
    }

    public static func le(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .le, args: args, parent: nil, file: file, line: line)
    }

    public static func line(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .line, args: args, parent: nil, file: file, line: line)
    }

    public static func literal(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .literal, args: args, parent: nil, file: file, line: line)
    }

    public static func lt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .lt, args: args, parent: nil, file: file, line: line)
    }

    public static func map(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .map, args: args, parent: nil, file: file, line: line)
    }

    public static func march(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .march, args: [], parent: nil, file: file, line: line)
    }

    public static func max(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .max, args: args, parent: nil, file: file, line: line)
    }

    public static func maxval(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .maxval, args: [], parent: nil, file: file, line: line)
    }

    public static func may(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .may, args: [], parent: nil, file: file, line: line)
    }

    public static func min(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .min, args: args, parent: nil, file: file, line: line)
    }

    public static func minval(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .minval, args: [], parent: nil, file: file, line: line)
    }

    public static func mod(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .mod, args: args, parent: nil, file: file, line: line)
    }

    public static func monday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .monday, args: [], parent: nil, file: file, line: line)
    }

    public static func mul(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .mul, args: args, parent: nil, file: file, line: line)
    }

    public static func ne(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ne, args: args, parent: nil, file: file, line: line)
    }

    public static func not(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .not, args: args, parent: nil, file: file, line: line)
    }

    public static func november(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .november, args: [], parent: nil, file: file, line: line)
    }

    public static func now(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .now, args: [], parent: nil, file: file, line: line)
    }

    public static func object(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .object, args: args, parent: nil, file: file, line: line)
    }

    public static func october(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .october, args: [], parent: nil, file: file, line: line)
    }

    public static func or(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .or, args: args, parent: nil, file: file, line: line)
    }

    public static func point(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .point, args: args, parent: nil, file: file, line: line)
    }

    public static func polygon(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .polygon, args: args, parent: nil, file: file, line: line)
    }

    public static func random(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .random, args: args, parent: nil, file: file, line: line)
    }

    public static func range(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .range, args: args, parent: nil, file: file, line: line)
    }

    public static func reduce(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .reduce, args: args, parent: nil, file: file, line: line)
    }

    public static func round(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .round, args: args, parent: nil, file: file, line: line)
    }

    public static func saturday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .saturday, args: [], parent: nil, file: file, line: line)
    }

    public static func september(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .september, args: [], parent: nil, file: file, line: line)
    }

    public static func sub(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .sub, args: args, parent: nil, file: file, line: line)
    }

    public static func sum(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .sum, args: args, parent: nil, file: file, line: line)
    }

    public static func sunday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .sunday, args: [], parent: nil, file: file, line: line)
    }

    public static func table(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlTable {
        return ReqlTable(term: .table, args: args, parent: nil, file: file, line: line)
    }

    public static func tableCreate(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .tableCreate, args: args, parent: nil, file: file, line: line)
    }

    public static func tableDrop(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .tableDrop, args: args, parent: nil, file: file, line: line)
    }

    public static func tableList(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .tableList, args: args, parent: nil, file: file, line: line)
    }

    public static func thursday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .thursday, args: [], parent: nil, file: file, line: line)
    }

    public static func time(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .time, args: args, parent: nil, file: file, line: line)
    }

    public static func tuesday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .tuesday, args: [], parent: nil, file: file, line: line)
    }

    public static func typeOf(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .typeOf, args: args, parent: nil, file: file, line: line)
    }

    public static func union(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .union, args: args, parent: nil, file: file, line: line)
    }

    public static func uuid(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .uuid, args: args, parent: nil, file: file, line: line)
    }

    public static func wednesday(file: String = #file, line: Int = #line) -> ReqlExpr {
        return ReqlExpr(term: .wednesday, args: [], parent: nil, file: file, line: line)
    }
}
