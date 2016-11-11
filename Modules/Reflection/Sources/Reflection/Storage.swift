func mutableStorageForInstance(_ instance: inout Any) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(mutating: storageForInstance(&instance))
}

func storageForInstance(_ instance: inout Any) -> UnsafeRawPointer {
    return withUnsafePointer(to: &instance) { pointer in
        if type(of: instance) is AnyClass {
            return UnsafeRawPointer(bitPattern: UnsafePointer<Int>(pointer).pointee)!
        } else if sizeofValue(instance) <= 3 * sizeof(Int.self) {
            return UnsafeRawPointer(pointer)
        } else {
            return UnsafeRawPointer(bitPattern: UnsafePointer<Int>(pointer).pointee)!
        }
    }
}

func mutableStorageForInstance<T>(_ instance: inout T) -> UnsafeMutableRawPointer {
    return UnsafeMutableRawPointer(mutating: storageForInstance(&instance))
}

func storageForInstance<T>(_ instance: inout T) -> UnsafeRawPointer {
    return withUnsafePointer(to: &instance) { pointer in
        if type(of: instance) is AnyClass {
            return UnsafeRawPointer(bitPattern: UnsafePointer<Int>(pointer).pointee)!
        } else {
            return UnsafeRawPointer(pointer)
        }
    }
}
