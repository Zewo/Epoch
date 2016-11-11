private struct HashedType : Hashable {
    let hashValue: Int
    init(_ type: Any.Type) {
        hashValue = unsafeBitCast(type, to: Int.self)
    }
}

private func == (lhs: HashedType, rhs: HashedType) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

private var cachedProperties = [HashedType : Array<Property.Description>]()

/// An instance property
public struct Property {
    public let key: String
    public let value: Any

    /// An instance property description
    public struct Description {
        public let key: String
        public let type: Any.Type
        let offset: Int
    }
}

/// Retrieve properties for `instance`
public func properties(_ instance: Any) throws -> [Property] {
    let props = try properties(type(of: instance))
    var copy = instance
    let storage = storageForInstance(&copy)
    return props.map { nextProperty(description: $0, storage: storage) }
}

private func nextProperty(description: Property.Description, storage: UnsafeRawPointer) -> Property {
    return Property(
        key: description.key,
        value: AnyExistentialContainer(
            type: description.type,
            pointer: storage.advanced(by: description.offset)
        ).any
    )
}

/// Retrieve property descriptions for `type`
public func properties(_ type: Any.Type) throws -> [Property.Description] {
    let hashedType = HashedType(type)
    if let properties = cachedProperties[hashedType] {
        return properties
    } else if let nominalType = Metadata.Struct(type: type) {
        return try fetchAndSaveProperties(nominalType: nominalType, hashedType: hashedType)
    } else if let nominalType = Metadata.Class(type: type) {
        return try fetchAndSaveProperties(nominalType: nominalType, hashedType: hashedType)
    } else {
        throw ReflectionError.notStruct(type: type)
    }
}

private func fetchAndSaveProperties<T : NominalType>(nominalType: T, hashedType: HashedType) throws -> [Property.Description] {
    let properties = try propertiesForNominalType(nominalType)
    cachedProperties[hashedType] = properties
    return properties
}

private func propertiesForNominalType<T : NominalType>(_ type: T) throws -> [Property.Description] {
    guard type.nominalTypeDescriptor.numberOfFields != 0 else { return [] }
    guard let fieldTypes = type.fieldTypes, let fieldOffsets = type.fieldOffsets else {
        throw ReflectionError.unexpected
    }
    let fieldNames = type.nominalTypeDescriptor.fieldNames
    return (0..<type.nominalTypeDescriptor.numberOfFields).map { i in
        return Property.Description(key: fieldNames[i], type: fieldTypes[i], offset: fieldOffsets[i])
    }
}
