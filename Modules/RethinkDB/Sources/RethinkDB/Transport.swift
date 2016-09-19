import Foundation

public protocol Transport {
    func read(maxBytes: Int) throws -> [UInt8]
    func write(bytes: [UInt8]) throws
    func close() throws
}
