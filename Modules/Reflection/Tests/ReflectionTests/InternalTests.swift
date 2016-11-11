import XCTest
@testable import Reflection

public class InternalTests : XCTestCase {
    
    func testShallowMetadata() {
        func testShallowMetadata<T>(type: T.Type, expectedKind: Metadata.Kind) {
            let shallowMetadata = Metadata(type: type)
            XCTAssert(shallowMetadata.kind == expectedKind, "\(shallowMetadata.kind) does not match expected \(expectedKind)")
            XCTAssert(shallowMetadata.valueWitnessTable.size == sizeof(type))
            XCTAssert(shallowMetadata.valueWitnessTable.stride == strideof(type))
        }
        testShallowMetadata(type: Person.self, expectedKind: .struct)
        testShallowMetadata(type: Optional<Person>.self, expectedKind: .optional)
        testShallowMetadata(type: (String, Int).self, expectedKind: .tuple)
        testShallowMetadata(type: ((String) -> Int).self, expectedKind: .function)
        testShallowMetadata(type: Any.self, expectedKind: .existential)
        testShallowMetadata(type: String.Type.self, expectedKind: .metatype)
        testShallowMetadata(type: Any.Type.self, expectedKind: .existentialMetatype)
        testShallowMetadata(type: ReferencePerson.self, expectedKind: .class)
    }

    func testNominalMetadata() {
        func testMetadata<T : NominalType>(metadata: T, expectedName: String) {
            XCTAssert(metadata.nominalTypeDescriptor.numberOfFields == 3)
            XCTAssert(metadata.nominalTypeDescriptor.fieldNames == ["firstName", "lastName", "age"])
            XCTAssertNotNil(metadata.nominalTypeDescriptor.fieldTypesAccessor)
            XCTAssert(metadata.fieldTypes! == [String.self, String.self, Int.self] as [Any.Type])
        }
        if let metadata = Metadata.Struct(type: Person.self) {
            testMetadata(metadata: metadata, expectedName: "Person")
        } else {
            XCTFail()
        }
        if let metadata = Metadata.Class(type: ReferencePerson.self) {
            testMetadata(metadata: metadata, expectedName: "ReferencePerson")
        } else {
            XCTFail()
        }
    }

    func testTupleMetadata() {
        guard let metadata = Metadata.Tuple(type: (Int, name: String, Float, age: Int).self) else {
            return XCTFail()
        }
        for (label, expected) in zip(metadata.labels, [nil, "name", nil, "age"] as [String?]) {
            XCTAssert(label == expected)
        }
    }

    func testSuperclass() {
        guard let metadata = Metadata.Class(type: SubclassedPerson.self) else {
            return XCTFail()
        }
        XCTAssertNotNil(metadata.superclass) // ReferencePerson
    }
}

func == (lhs: [Any.Type], rhs: [Any.Type]) -> Bool {
    return zip(lhs, rhs).reduce(true) { $1.0 != $1.1 ? false : $0 }
}

extension InternalTests {
    public static var allTests: [(String, (InternalTests) -> () throws -> Void)] {
        return [
            ("testShallowMetadata", testShallowMetadata),
            ("testNominalMetadata", testNominalMetadata),
            ("testTupleMetadata", testTupleMetadata),
            ("testSuperclass", testSuperclass),
        ]
    }
}
