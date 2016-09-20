public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

public protocol StringInMappable: InMappable {
    init<Map: InMap>(mapper: StringInMapper<Map>) throws
}

struct City : InMappable, OutMappable {
    let name: String
    let population: UInt
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.population = try mapper.map(from: .population)
    }
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, City.Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.population, to: .population)
    }
    
    enum Keys : String, IndexPathElement {
        case name
        case population
    }
}

enum Gender : String {
    case male
    case female
}

struct Person : Mappable {
    let name: String
    let gender: Gender
    let city: City
    let identifier: Int
    let isRegistered: Bool
    let biographyPoints: [String]
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.gender = try mapper.map(from: .gender)
        self.city = try mapper.map(from: .city)
        self.identifier = try mapper.map(from: .identifier)
        self.isRegistered = try mapper.map(from: .registered)
        self.biographyPoints = try mapper.mapArray(from: .biographyPoints)
    }
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Person.Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.gender, to: .gender)
        try mapper.map(self.city, to: .city)
        try mapper.map(self.identifier, to: .identifier)
        try mapper.map(self.isRegistered, to: .registered)
        try mapper.mapArray(self.biographyPoints, to: .biographyPoints)
    }
    
    enum Keys : String, IndexPathElement {
        case name
        case gender
        case city
        case identifier
        case registered
        case biographyPoints
    }
}

/// and so on...

struct Club {
    let name: String
    let season: Int?
    let qualified: Bool
    
    enum Keys : String, IndexPathElement {
        case name
        case season
        case qualified
    }
}

extension Club : InMappable {
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.season = try? mapper.map(from: .season)
        self.qualified = try mapper.map(from: .qualified)
    }
}

extension Club : OutMappable {
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Club.Keys>) throws {
        try mapper.map(self.name, to: .name)
        try mapper.map(self.season ?? 0, to: .season)
        try mapper.map(self.qualified, to: .qualified)
    }
}

struct Album : Mappable {
    let songs: [String]
    enum Keys : String, IndexPathElement {
        case songs
    }
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.songs = try mapper.mapArray(from: .songs)
    }
    func outMap<Destination : OutMap>(mapper: inout OutMapper<Destination, Album.Keys>) throws {
        try mapper.mapArray(self.songs, to: .songs)
    }
}


