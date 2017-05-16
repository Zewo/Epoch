import struct Foundation.Data
import struct Foundation.UUID

public protocol ContentInitializable {
    init(content: Content) throws
}

public protocol ContentRepresentable {
    var content: Content { get }
}

public protocol ContentConvertible : ContentInitializable, ContentRepresentable {}

extension Content : ContentConvertible {
    public var content: Content {
        return self
    }
    
    public init(content: Content) throws {
        self = content
    }
}

extension Int : ContentConvertible {
    public var content: Content {
        return .int(self)
    }
    
    public init(content: Content) throws {
        guard case let .int(value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), content: content)
        }
        
        self = value
    }
}

extension Bool : ContentConvertible {
    public var content: Content {
        return .bool(self)
    }
    
    public init(content: Content) throws {
        guard case let .bool(value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), content: content)
        }
        
        self = value
    }
}

extension String : ContentConvertible {
    public var content: Content {
        return .string(self)
    }
    
    public init(content: Content) throws {
        guard case let .string(value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), content: content)
        }
        
        self = value
    }
}

extension Double : ContentConvertible {
    public var content: Content {
        return .double(self)
    }
    
    public init(content: Content) throws {
        guard case let .double(value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), content: content)
        }
        
        self = value
    }
}

extension Data : ContentConvertible {
    public var content: Content {
        return .data(self)
    }
    
    public init(content: Content) throws {
        guard case let .data(value) = content else {
            throw ContentError.cannotInitialize(type: type(of: self), content: content)
        }
        
        self = value
    }
}

extension UUID : ContentConvertible {
    public var content: Content {
        return .string(uuidString)
    }
    
    public init(content: Content) throws {
        guard case let .string(value) = content, let uuid = UUID(value) else {
            throw ContentError.cannotInitialize(type: type(of: self), content: content)
        }
        
        self = uuid
    }
}
