import XCTest
@testable import WebSocket

public class EventListenerTests : XCTestCase {
    func testCallSetsInactiveWhenCallCountReachesZero() {
        let listener = EventListener<Any>(calls: 2) { _ in }
        listener.active = true
        
        let called0 = try? listener.call("zero")
        XCTAssertTrue(called0!)
        XCTAssertTrue(listener.active)
        
        let called1 = try? listener.call("one")
        XCTAssertFalse(called1!)
        XCTAssertFalse(listener.active)
        
        let called2 = try? listener.call("three")
        XCTAssertFalse(called2!)
        XCTAssertFalse(listener.active)
    }
    
    func testStopSetsInactive() {
        let listener = EventListener<Any>(calls: 1) { _ in }
        listener.active = true
        
        listener.stop()
        
        XCTAssertFalse(listener.active)
    }
}

extension EventListenerTests {
    public static var allTests: [(String, (EventListenerTests) -> () throws -> Void)] {
        return [
            ("testCallSetsInactiveWhenCallCountReachesZero", testCallSetsInactiveWhenCallCountReachesZero),
            ("testStopSetsInactive", testStopSetsInactive),
        ]
    }
}
