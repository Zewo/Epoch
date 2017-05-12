import Axis

public protocol RowConvertible {
    init<T: RowProtocol>(row: T) throws
}

public protocol RowProtocol {
    associatedtype Result: ResultProtocol

    var result: Result { get }
    var index: Int { get }

    func data(_ field: QualifiedField) throws -> Buffer?
}

public enum RowProtocolError: Error {
    case expectedQualifiedField(QualifiedField)
    case unexpectedNilValue(QualifiedField)
}

public extension RowProtocol {

    public func data(_ field: QualifiedField) throws -> Buffer? {

        let fieldName: String


        if let alias = field.alias {
            fieldName = alias
        }
        else {
            fieldName = field.unqualifiedName
        }

        guard let fieldIndex = result.index(ofFieldByName: fieldName) else {
            throw RowProtocolError.expectedQualifiedField(field)
        }

        return result.data(atRow: index, forFieldIndex: fieldIndex)
    }

    public func data(_ field: QualifiedField) throws -> Buffer {
        guard let buffer: Buffer = try data(field) else {
            throw RowProtocolError.unexpectedNilValue(field)
        }

        return buffer
    }

    public func data(_ field: String) throws -> Buffer {
        let field = QualifiedField(field)
        guard let buffer: Buffer = try data(field) else {
            throw RowProtocolError.unexpectedNilValue(field)
        }

        return buffer
    }

    // MARK: - ValueConvertible

    public func value<T: ValueConvertible>(_ field: QualifiedField) throws -> T? {
        guard let buffer: Buffer = try data(field) else {
            return nil
        }

        return try T(rawSQLData: buffer)
    }

    public func value<T: ValueConvertible>(_ field: QualifiedField) throws -> T {
        guard let buffer: Buffer = try data(field) else {
            throw RowProtocolError.unexpectedNilValue(field)
        }

        return try T(rawSQLData: buffer)
    }

    // MARK - String support

    public func data(field: String) throws -> Buffer? {
        return try data(QualifiedField(field))
    }

    public func value<T: ValueConvertible>(_ field: String) throws -> T? {
        return try value(QualifiedField(field))
    }

    public func value<T: ValueConvertible>(_ field: String) throws -> T {
        return try value(QualifiedField(field))
    }
}

public protocol TableRowConvertible: TableProtocol, RowConvertible {
    init<Row: RowProtocol>(row: TableRow<Self, Row>) throws
}

extension TableRowConvertible {
    public init<Row: RowProtocol>(row: Row) throws {
        try self.init(row: TableRow(row: row))
    }
}

public struct TableRow<Table: TableProtocol, Row: RowProtocol>: RowProtocol {
    public var result: Row.Result
    public var index: Int
    private let _data: (QualifiedField) throws -> Buffer?

    public init(row: Row) {
        self.result = row.result
        self.index = row.index
        self._data = row.data
    }

    public func data(_ field: QualifiedField) throws -> Buffer? {
        return try self._data(field)
    }
}

extension TableRow where Table.Field.RawValue == String {
    public func value<T: ValueConvertible>(_ field: Table.Field) throws -> T {
        return try value(field.qualifiedField)
    }

    public func value<T: ValueConvertible>(_ field: Table.Field) throws -> T? {
        return try value(field.qualifiedField)
    }
}
