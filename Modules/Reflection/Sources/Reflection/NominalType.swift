protocol NominalType : MetadataType {
    var nominalTypeDescriptorOffsetLocation: Int { get }
}

extension NominalType {
    var nominalTypeDescriptor: NominalTypeDescriptor {
        let pointer = UnsafePointer<Int>(self.pointer)
        let base = pointer.advanced(by: nominalTypeDescriptorOffsetLocation)
        return NominalTypeDescriptor(pointer: relativePointer(base: base, offset: base.pointee))
    }

    var fieldTypes: [Any.Type]? {
        guard let function = nominalTypeDescriptor.fieldTypesAccessor else { return nil }
        return (0..<nominalTypeDescriptor.numberOfFields).map {
            return unsafeBitCast(function(UnsafePointer<Int>(pointer)).advanced(by: $0).pointee, to: Any.Type.self)
        }
    }

    var fieldOffsets: [Int]? {
        let vectorOffset = nominalTypeDescriptor.fieldOffsetVector
        guard vectorOffset != 0 else { return nil }
        return (0..<nominalTypeDescriptor.numberOfFields).map {
            return UnsafePointer<Int>(pointer)[vectorOffset + $0]
        }
    }
}
