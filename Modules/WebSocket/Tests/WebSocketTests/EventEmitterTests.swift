import XCTest
@testable import WebSocket

public class EventEmitterTests : XCTestCase {
    func testCallsActiveListeners() {
        let emitter = EventEmitter<Any>()
        
        var activeCalled = false
        let active = emitter.addListener() { _ in
            activeCalled = true
        }
        active.active = true
        
        var inactiveCalled = false
        let inactive = emitter.addListener() { _ in
            inactiveCalled = true
        }
        inactive.active = false
        
        do { try emitter.emit("whatever") } catch { print(error) }
        
        XCTAssertTrue(activeCalled)
        XCTAssertFalse(inactiveCalled)
    }
}

extension EventEmitterTests {
    public static var allTests: [(String, (EventEmitterTests) -> () throws -> Void)] {
        return [
            ("testCallsActiveListeners", testCallsActiveListeners),
        ]
    }
}
