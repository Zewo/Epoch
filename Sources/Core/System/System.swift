#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public enum System {
    public static var workingDirectory: String {
        let buffer = UnsafeMutableRawBufferPointer.allocate(byteCount: Int(PATH_MAX), alignment: MemoryLayout<UInt8>.alignment)
        
        defer {
            buffer.deallocate()
        }
        
        let bufferPointer = buffer.baseAddress?.assumingMemoryBound(to: Int8.self)
        
        guard let cString = getcwd(bufferPointer, buffer.count) else {
            return "./"
        }
        
        return String(cString: cString)
    }
}
