public protocol MapInitializable {
    init(map: Map) throws
}

public protocol MapRepresentable : MapFallibleRepresentable {
    var map: Map { get }
}

public protocol MapFallibleRepresentable {
    func asMap() throws -> Map
}

extension MapRepresentable {
    public func asMap() throws -> Map {
        return map
    }
}

public protocol MapConvertible : MapInitializable, MapFallibleRepresentable {}
