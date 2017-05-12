import Venice
import Core

public protocol Host {
    func accept(deadline: Deadline) throws -> DuplexStream
}
