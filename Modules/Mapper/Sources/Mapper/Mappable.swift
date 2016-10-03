public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

struct Batman : InMappable {
    let title: String
    let points: [Int]
    enum Keys : String, IndexPathElement {
        case title, points
    }
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.title = try mapper.map(from: .title)
        self.points = try mapper.map(from: .points)
    }
}

struct Bat : BasicInMappable {
    let title: String
    let points: [Int]
    init<Source : InMap>(mapper: BasicInMapper<Source>) throws {
        self.title = try mapper.map(from: "title")
        self.points = try mapper.map(from: "points")
    }
}
