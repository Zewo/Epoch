public typealias MapProtocol = InMap & OutMap
public typealias Mappable = InMappable & OutMappable

public protocol StringInMappable: InMappable {
    init<Map: InMap>(mapper: StringInMapper<Map>) throws
}

struct City : InMappable {
    let name: String
    let population: UInt
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.population = try mapper.map(from: .population)
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

struct Person : InMappable {
    let name: String
    let gender: Gender
    let city: City
    let identifier: Int
    let isRegistered: Bool
    
    init<Source : InMap>(mapper: InMapper<Source, Keys>) throws {
        self.name = try mapper.map(from: .name)
        self.gender = try mapper.map(from: .gender)
        self.city = try mapper.map(from: .city)
        self.identifier = try mapper.map(from: .identifier)
        self.isRegistered = try mapper.map(from: .registered)
    }
    enum Keys : String, IndexPathElement {
        case name
        case gender
        case city
        case identifier
        case registered
    }
}
