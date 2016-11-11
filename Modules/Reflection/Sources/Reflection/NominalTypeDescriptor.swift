struct NominalTypeDescriptor : PointerType {
    var pointer: UnsafePointer<_NominalTypeDescriptor>

    var mangledName: String {
        return String(cString: relativePointer(base: pointer, offset: pointer.pointee.mangledName) as UnsafePointer<CChar>)
    }

    var numberOfFields: Int {
        return Int(pointer.pointee.numberOfFields)
    }

    var fieldOffsetVector: Int {
        return Int(pointer.pointee.fieldOffsetVector)
    }

    var fieldNames: [String] {
        let p = UnsafePointer<Int32>(self.pointer)
        return Array(utf8Strings: relativePointer(base: p.advanced(by: 3), offset: self.pointer.pointee.fieldNames))
    }

    typealias FieldsTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<UnsafePointer<Int>>

    var fieldTypesAccessor: FieldsTypeAccessor? {
        let offset = pointer.pointee.fieldTypesAccessor
        guard offset != 0 else { return nil }
        let p = UnsafePointer<Int32>(self.pointer)
        let offsetPointer: UnsafePointer<Int> = relativePointer(base: p.advanced(by: 4), offset: offset)
        return unsafeBitCast(offsetPointer, to: FieldsTypeAccessor.self)
    }
}

struct _NominalTypeDescriptor {
    var mangledName: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
    var fieldNames: Int32
    var fieldTypesAccessor: Int32
}
