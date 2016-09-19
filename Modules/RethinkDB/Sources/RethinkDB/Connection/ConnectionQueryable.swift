import Foundation

protocol ConnectionQueryable {
    func run(ast: ReqlAst) throws -> JSON
}
