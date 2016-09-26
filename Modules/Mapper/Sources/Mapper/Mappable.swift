import Foundation

public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

public protocol StringInMappable : InMappable {
    init<Source : InMap>(mapper: StringInMapper<Source>) throws
}

public protocol StringOutMappable : OutMappable {
    func outMap<Destination : OutMap>(mapper: inout StringOutMapper<Destination>) throws
}

struct Planet : StringInMappable, StringOutMappable {
    
    let radius: Int
    
    init<Source : InMap>(mapper: StringInMapper<Source>) throws {
        self.radius = try mapper.map(from: "radius")
    }
    
    func outMap<Destination : OutMap>(mapper: inout StringOutMapper<Destination>) throws {
        try mapper.map(self.radius, to: "radius")
    }
    
}

struct City {
    
    let name: String
    let population: Int
    
    enum Keys : String, IndexPathElement {
        case name, population
    }
    
}

struct Album : Mappable {
    
    let songs: [String]
    
    enum Keys : String, IndexPathElement {
        case songs
    }
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.songs = try mapper.map(from: .songs)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Album.Keys>) throws {
        try mapper.mapArray(self.songs, to: .songs)
    }
    
}

extension City : InMappable {
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.population = try mapper.map(from: .population)
    }
}

extension City : OutMappable {
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.population, to: .population)
    }
}

enum Wood : String {
    case mahogany
    case koa
    case cedar
    case spruce
}

enum Strings : Int {
    case four = 4
    case six = 6
    case seven = 7
}

struct Guitar : Mappable {
    
    let wood: Wood
    let strings: Strings
    
    enum Keys : String, IndexPathElement {
        case wood, strings
    }
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.wood = try mapper.map(from: .wood)
        self.strings = try mapper.map(from: .strings)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Guitar.Keys>) throws {
        try mapper.map(self.wood, to: .wood)
        try mapper.map(self.strings, to: .strings)
    }
    
}

struct Sport : Mappable {
    
    let name: String
    
    enum Keys : String, IndexPathElement {
        case name
    }
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Sport.Keys>) throws {
        try mapper.map(self.name, to: .name)
    }
    
}

struct Team : Mappable {
    
    let sport: Sport
    let name: String
    let foundationYear: Int
    
    enum Keys : String, IndexPathElement {
        case sport
        case name
        case foundationYear = "foundation-year"
    }
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.sport = try mapper.map(from: .sport)
        self.name = try mapper.map(from: .name)
        self.foundationYear = try mapper.map(from: .foundationYear)
    }
    
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Team.Keys>) throws {
        try mapper.map(self.sport, to: .sport)
        try mapper.map(self.name, to: .name)
        try mapper.map(self.foundationYear, to: .foundationYear)
    }
    
}
