// MARK: Subscripts

extension Map {
    public subscript(indexPath: IndexPathElement...) -> Map? {
        get {
            return self[indexPath]
        }

        set(value) {
            self[indexPath] = value
        }
    }

    public subscript(indexPath: [IndexPathElement]) -> Map? {
        get {
            return (try? self.get(indexPath)) ?? Optional.none
        }

        set(value) {
            do {
                switch value {
                case let value?: try self.set(value, for: indexPath, merging: true)
                case .none: try self.remove(indexPath)
                }
            } catch {
                fatalError(String(describing: error))
            }
        }
    }

    private func get(_ indexPath: [IndexPathElement]) throws -> Map {
        var value: Map = self

        for element in indexPath {
            switch element.indexPathValue {
            case .index(let index):
                let array: [Map] = try value.asArray()
                if array.indices.contains(index) {
                    value = array[index]
                } else {
                    throw MapError.outOfBounds
                }

            case .key(let key):
                let dictionary = try value.asDictionary()
                if let newValue = dictionary[key] {
                    value = newValue
                } else {
                    throw MapError.valueNotFound
                }
            }
        }

        return value
    }

    private mutating func set<T : MapRepresentable>(_ value: T?, for indexPath: [IndexPathElement], merging: Bool) throws {
        var indexPath = indexPath

        guard let first = indexPath.first else {
            return self = value.map
        }

        indexPath.removeFirst()

        if indexPath.isEmpty {
            switch first.indexPathValue {
            case .index(let index):
                if case .array(var array) = self {
                    if !array.indices.contains(index) {
                        throw MapError.outOfBounds
                    }
                    array[index] = value.map
                    self = .array(array)
                } else {
                    throw MapError.incompatibleType
                }
            case .key(let key):
                if case .dictionary(var dictionary) = self {
                    if let newValue = value?.map {
                        if let existingDictionary = dictionary[key]?.dictionary,
                            let newDictionary = newValue.dictionary,
                            merging {
                            var combinedDictionary: [String: Map] = [:]

                            for (key, value) in existingDictionary {
                                combinedDictionary[key] = value
                            }

                            for (key, value) in newDictionary {
                                combinedDictionary[key] = value
                            }

                            dictionary[key] = .dictionary(combinedDictionary)
                        } else {
                            dictionary[key] = newValue
                        }
                    } else {
                        dictionary[key] = Optional.none
                    }
                    self = .dictionary(dictionary)
                } else {
                    throw MapError.incompatibleType
                }
            }
        } else {
            var next = self[first] ?? first.constructEmptyContainer
            try next.set(value, for: indexPath, merging: true)
            try self.set(next, for: [first], merging: true)
        }
    }

    private mutating func remove(_ indexPath: [IndexPathElement]) throws {
        var indexPath = indexPath

        guard let first = indexPath.first else {
            return self = .null
        }

        indexPath.removeFirst()

        if indexPath.isEmpty {
            guard case .dictionary(var dictionary) = self, case .key(let key) = first.indexPathValue else {
                throw MapError.incompatibleType
            }

            dictionary[key] = nil
            self = .dictionary(dictionary)
        } else {
            guard var next = self[first] else {
                throw MapError.valueNotFound
            }
            try next.remove(indexPath)
            try self.set(next, for: [first], merging: false)
        }
    }
}

// MARK: IndexPath

extension String {
    public func indexPath() -> [IndexPathValue] {
        return self.split(separator: ".").map {
            if let index = Int($0) {
                return .index(index)
            }
            return .key($0)
        }
    }
}

extension IndexPathElement {
    var constructEmptyContainer: Map {
        switch indexPathValue {
        case .index: return []
        case .key: return [:]
        }
    }
}
