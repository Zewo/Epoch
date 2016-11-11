public protocol EntityProtocol {
    associatedtype Model: ModelProtocol

    var model: Model { get set }
}

public protocol PersistedEntityProtocol: EntityProtocol, Equatable {
    var primaryKey: Model.PrimaryKey { get set }
}

public extension EntityProtocol where Model.Field.RawValue == String {
    public static func get<Connection: ConnectionProtocol> (_ pk: Model.PrimaryKey, connection: Connection) throws -> PersistedEntity<Model>? where Connection.Result.Iterator.Element: RowProtocol {

        var select = Model.select(where: Model.Field.primaryKey == pk)
        select.limit(to: 1)
        select.offset(by: 0)

        guard let row = try connection.execute(select).first else {
            return nil
        }

        let tableRow = TableRow<Model, Connection.Result.Iterator.Element>(row: row)

        return PersistedEntity(model: try Model.init(row: tableRow), primaryKey: try tableRow.value(Model.Field.primaryKey))
    }

    public static func fetchAll<Connection: ConnectionProtocol> (connection: Connection) throws -> [PersistedEntity<Model>] where Connection.Result.Iterator.Element: RowProtocol {
        return try fetch(where: nil, limit: nil, offset: nil, connection: connection)
    }

    public static func first<Connection: ConnectionProtocol> (where predicate: Predicate? = nil, connection: Connection) throws -> PersistedEntity<Model>? where Connection.Result.Iterator.Element: RowProtocol {
        return try fetch(where: predicate, limit: 1, offset: 0, connection: connection).first
    }

    public static func fetch<Connection: ConnectionProtocol> (where predicate: Predicate? = nil, limit: Int? = nil, offset: Int? = nil, connection: Connection) throws -> [PersistedEntity<Model>] where Connection.Result.Iterator.Element: RowProtocol {
        var select = Model.select

        if let predicate = predicate {
            select.filter(predicate)
        }

        if let limit = limit {
            select.limit(to: limit)
        }

        if let offset = offset {
            select.offset(by: offset)
        }

        return try connection.execute(select).map { row in
            let tableRow = TableRow<Model, Connection.Result.Iterator.Element>(row: row)

            return try PersistedEntity(model: Model(row: tableRow), primaryKey: tableRow.value(Model.Field.primaryKey))
        }
    }

    public func create<Connection: ConnectionProtocol> (connection: Connection) throws -> PersistedEntity<Model> where Connection.Result.Iterator.Element: RowProtocol {
        return try connection.transaction {
            try self.model.willSave()
            try self.model.willCreate()

            let result = try connection.execute(Model.insert(self.model.serialize()), returnInsertedRows: true)

            guard let row = result.first else {
                throw EntityError("Failed to retreieve row from insert result")
            }

            guard let pk: Model.PrimaryKey = try row.value(Model.Field.primaryKey.qualifiedField) else {
                throw EntityError("Failed to retreieve primary key from insert")
            }

            var new = PersistedEntity(model: self.model, primaryKey: pk)

            new.model.didCreate()
            new.model.didSave()

            new = try new.refresh(connection: connection)

            return new
        }
    }

    public func save<Connection: ConnectionProtocol> (connection: Connection) throws -> PersistedEntity<Model>  where Connection.Result.Iterator.Element: RowProtocol {
        return try create(connection: connection)
    }
}

public extension PersistedEntityProtocol where Model.Field.RawValue == String {
    public func delete<Connection: ConnectionProtocol> (connection: Connection) throws -> Entity<Model> where Connection.Result.Iterator.Element: RowProtocol {
        try connection.execute(Model.delete(where: Model.Field.primaryKey == self.primaryKey))

        return Entity(model: model)
    }

    public func refresh<Connection: ConnectionProtocol> (connection: Connection) throws -> PersistedEntity<Model>  where Connection.Result.Iterator.Element: RowProtocol {
        try model.willRefresh()

        guard let refreshed = try type(of: self).get(primaryKey, connection: connection) else {
            throw EntityError("Failed to re-fetch model with primary key \(primaryKey)")
        }

        refreshed.model.didRefresh()

        return refreshed
    }

    public func update<Connection: ConnectionProtocol> (connection: Connection) throws -> PersistedEntity<Model>  where Connection.Result.Iterator.Element: RowProtocol {
        try model.willSave()
        try model.willUpdate()

        try connection.execute(Model.update(model.serialize()))

        let new = try refresh(connection: connection)
        new.model.didUpdate()
        new.model.didSave()

        return new
    }

    public func update<Connection: ConnectionProtocol> (newPrimaryKey: Model.PrimaryKey, connection: Connection) throws -> PersistedEntity<Model>  where Connection.Result.Iterator.Element: RowProtocol {
        try model.willSave()
        try model.willUpdate()

        // add primary key to update parameters
        var serialized = model.serialize()
        serialized[Model.Field.primaryKey] = newPrimaryKey

        try connection.execute(Model.update(serialized))

        var entity = self
        entity.primaryKey = newPrimaryKey

        let new = try entity.refresh(connection: connection)
        new.model.didUpdate()
        new.model.didSave()

        return new
    }

    public func save<Connection: ConnectionProtocol> (connection: Connection) throws -> PersistedEntity<Model>  where Connection.Result.Iterator.Element: RowProtocol {
        return try update(connection: connection)
    }
}

public struct Entity<Model: ModelProtocol> : EntityProtocol where Model.Field.RawValue == String {
    public var model: Model

    public init(model: Model) {
        self.model = model
    }
}

public struct PersistedEntity<Model: ModelProtocol> : PersistedEntityProtocol where Model.Field.RawValue == String {
    public var model: Model
    public var primaryKey: Model.PrimaryKey

    public init(model: Model, primaryKey: Model.PrimaryKey) {
        self.model = model
        self.primaryKey = primaryKey
    }
}

public func == <Entity: PersistedEntityProtocol> (lhs: Entity, rhs: Entity) -> Bool {
    return lhs.primaryKey == rhs.primaryKey
}
