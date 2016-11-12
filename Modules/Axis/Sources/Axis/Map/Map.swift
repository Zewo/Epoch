public enum Map {
    case null
    case bool(Bool)
    case double(Double)
    case int(Int)
    case string(String)
    case buffer(Buffer)
    case array([Map])
    case dictionary([String: Map])
}

// MARK: MapError

public enum MapError : Error {
    case incompatibleType
    case outOfBounds
    case valueNotFound
    case notMapInitializable(Any.Type)
    case notMapRepresentable(Any.Type)
    case notMapDictionaryKeyInitializable(Any.Type)
    case notMapDictionaryKeyRepresentable(Any.Type)
    case cannotInitialize(type: Any.Type, from: Any.Type)
}
