extension ReqlExpr {
    public func add(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .add, args: args, parent: self, file: file, line: line)
    }

    public func and(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .and, args: args, parent: self, file: file, line: line)
    }

    public func append(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .append, args: args, parent: self, file: file, line: line)
    }

    public func avg(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .avg, args: args, parent: self, file: file, line: line)
    }

    public func between(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .between, args: args, parent: self, file: file, line: line)
    }

    public func bracket(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .bracket, args: args, parent: self, file: file, line: line)
    }

    public func ceil(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ceil, args: args, parent: self, file: file, line: line)
    }

    public func changes(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .changes, args: args, parent: self, file: file, line: line)
    }

    public func changeAt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .changeAt, args: args, parent: self, file: file, line: line)
    }

    public func coerceTo(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .coerceTo, args: args, parent: self, file: file, line: line)
    }

    public func concatMap(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .concatMap, args: args, parent: self, file: file, line: line)
    }

    public func contains(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .contains, args: args, parent: self, file: file, line: line)
    }

    public func count(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .count, args: args, parent: self, file: file, line: line)
    }

    public func date(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .date, args: args, parent: self, file: file, line: line)
    }

    public func day(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .day, args: args, parent: self, file: file, line: line)
    }

    public func dayOfWeek(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .dayOfWeek, args: args, parent: self, file: file, line: line)
    }

    public func dayOfYear(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .dayOfYear, args: args, parent: self, file: file, line: line)
    }

    public func `default`(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .`default`, args: args, parent: self, file: file, line: line)
    }

    public func delete(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .delete, args: args, parent: self, file: file, line: line)
    }

    public func deleteAt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .deleteAt, args: args, parent: self, file: file, line: line)
    }

    public func difference(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .difference, args: args, parent: self, file: file, line: line)
    }

    public func distance(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .distance, args: args, parent: self, file: file, line: line)
    }

    public func distinct(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .distinct, args: args, parent: self, file: file, line: line)
    }

    public func div(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .div, args: args, parent: self, file: file, line: line)
    }

    public func downcase(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .downcase, args: args, parent: self, file: file, line: line)
    }

    public func during(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .during, args: args, parent: self, file: file, line: line)
    }

    public func eq(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .eq, args: args, parent: self, file: file, line: line)
    }

    public func eqJoin(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .eqJoin, args: args, parent: self, file: file, line: line)
    }

    public func fill(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .fill, args: args, parent: self, file: file, line: line)
    }

    public func filter(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .filter, args: args, parent: self, file: file, line: line)
    }

    public func floor(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .floor, args: args, parent: self, file: file, line: line)
    }

    public func fold(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .fold, args: args, parent: self, file: file, line: line)
    }

    public func forEach(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .forEach, args: args, parent: self, file: file, line: line)
    }

    public func funcall(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .funcall, args: args, parent: self, file: file, line: line)
    }

    public func `do`(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .funcall, args: args, parent: self, file: file, line: line)
    }

    public func ge(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ge, args: args, parent: self, file: file, line: line)
    }

    public func getField(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .getField, args: args, parent: self, file: file, line: line)
    }

    public func group(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .group, args: args, parent: self, file: file, line: line)
    }

    public func gt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .gt, args: args, parent: self, file: file, line: line)
    }

    public func hasFields(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .hasFields, args: args, parent: self, file: file, line: line)
    }

    public func hours(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .hours, args: args, parent: self, file: file, line: line)
    }

    public func includes(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .includes, args: args, parent: self, file: file, line: line)
    }

    public func info(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .info, args: args, parent: self, file: file, line: line)
    }

    public func innerJoin(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .innerJoin, args: args, parent: self, file: file, line: line)
    }

    public func insertAt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .insertAt, args: args, parent: self, file: file, line: line)
    }

    public func intersects(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .intersects, args: args, parent: self, file: file, line: line)
    }

    public func inTimezone(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .inTimezone, args: args, parent: self, file: file, line: line)
    }

    public func isEmpty(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .isEmpty, args: args, parent: self, file: file, line: line)
    }

    public func keys(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .keys, args: args, parent: self, file: file, line: line)
    }

    public func le(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .le, args: args, parent: self, file: file, line: line)
    }

    public func limit(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .limit, args: args, parent: self, file: file, line: line)
    }

    public func lt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .lt, args: args, parent: self, file: file, line: line)
    }

    public func map(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .map, args: args, parent: self, file: file, line: line)
    }

    public func match(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .match, args: args, parent: self, file: file, line: line)
    }

    public func max(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .max, args: args, parent: self, file: file, line: line)
    }

    public func merge(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .merge, args: args, parent: self, file: file, line: line)
    }

    public func min(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .min, args: args, parent: self, file: file, line: line)
    }

    public func minutes(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .minutes, args: args, parent: self, file: file, line: line)
    }

    public func mod(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .mod, args: args, parent: self, file: file, line: line)
    }

    public func month(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .month, args: args, parent: self, file: file, line: line)
    }

    public func mul(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .mul, args: args, parent: self, file: file, line: line)
    }

    public func ne(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ne, args: args, parent: self, file: file, line: line)
    }

    public func not(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .not, args: args, parent: self, file: file, line: line)
    }

    public func nth(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .nth, args: args, parent: self, file: file, line: line)
    }

    public func offsetsOf(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .offsetsOf, args: args, parent: self, file: file, line: line)
    }

    public func or(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .or, args: args, parent: self, file: file, line: line)
    }

    public func orderBy(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .orderBy, args: args, parent: self, file: file, line: line)
    }

    public func outerJoin(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .outerJoin, args: args, parent: self, file: file, line: line)
    }

    public func pluck(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .pluck, args: args, parent: self, file: file, line: line)
    }

    public func polygonSub(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .polygonSub, args: args, parent: self, file: file, line: line)
    }

    public func prepend(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .prepend, args: args, parent: self, file: file, line: line)
    }

    public func reduce(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .reduce, args: args, parent: self, file: file, line: line)
    }

    public func replace(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .replace, args: args, parent: self, file: file, line: line)
    }

    public func round(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .round, args: args, parent: self, file: file, line: line)
    }

    public func sample(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .sample, args: args, parent: self, file: file, line: line)
    }

    public func seconds(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .seconds, args: args, parent: self, file: file, line: line)
    }

    public func setDifference(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .setDifference, args: args, parent: self, file: file, line: line)
    }

    public func setInsert(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .setInsert, args: args, parent: self, file: file, line: line)
    }

    public func setIntersection(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .setIntersection, args: args, parent: self, file: file, line: line)
    }

    public func setUnion(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .setUnion, args: args, parent: self, file: file, line: line)
    }

    public func skip(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .skip, args: args, parent: self, file: file, line: line)
    }

    public func slice(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .slice, args: args, parent: self, file: file, line: line)
    }

    public func spliceAt(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .spliceAt, args: args, parent: self, file: file, line: line)
    }

    public func split(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .split, args: args, parent: self, file: file, line: line)
    }

    public func sub(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .sub, args: args, parent: self, file: file, line: line)
    }

    public func sum(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .sum, args: args, parent: self, file: file, line: line)
    }

    public func timezone(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .timezone, args: args, parent: self, file: file, line: line)
    }

    public func timeOfDay(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .timeOfDay, args: args, parent: self, file: file, line: line)
    }

    public func toEpochTime(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .toEpochTime, args: args, parent: self, file: file, line: line)
    }

    public func toGeojson(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .toGeojson, args: args, parent: self, file: file, line: line)
    }

    public func toISO8601(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .toISO8601, args: args, parent: self, file: file, line: line)
    }

    public func toJSONString(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .toJSONString, args: args, parent: self, file: file, line: line)
    }

    public func toJSON(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .toJSONString, args: args, parent: self, file: file, line: line)
    }

    public func typeOf(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .typeOf, args: args, parent: self, file: file, line: line)
    }

    public func ungroup(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .ungroup, args: args, parent: self, file: file, line: line)
    }

    public func union(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .union, args: args, parent: self, file: file, line: line)
    }

    public func upcase(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .upcase, args: args, parent: self, file: file, line: line)
    }

    public func update(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .update, args: args, parent: self, file: file, line: line)
    }

    public func values(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .values, args: args, parent: self, file: file, line: line)
    }

    public func without(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .without, args: args, parent: self, file: file, line: line)
    }

    public func withFields(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .withFields, args: args, parent: self, file: file, line: line)
    }

    public func year(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .year, args: args, parent: self, file: file, line: line)
    }

    public func zip(file: String = #file, line: Int = #line, _ args: Any ...) -> ReqlExpr {
        return ReqlExpr(term: .zip, args: args, parent: self, file: file, line: line)
    }
}
