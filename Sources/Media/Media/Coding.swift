enum MapSuperKey : String, CodingKey {
    case `super`
}

extension String : CodingKey {
    public var stringValue: String {
        return self
    }
    
    public init?(stringValue: String) {
        self = stringValue
    }
    
    public var intValue: Int? {
        return Int(self)
    }
    
    public init?(intValue: Int) {
        self = String(intValue)
    }
}

extension Int : CodingKey {
    public var stringValue: String {
        return description
    }
    
    public init?(stringValue: String) {
        guard let int = Int(stringValue) else {
            return nil
        }
        
        self = int
    }
    
    public var intValue: Int? {
        return self
    }
    
    public init?(intValue: Int) {
        self = intValue
    }
}

extension EncodingError.Context {
    public init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.debugDescription = ""
        self.underlyingError = nil
    }
    
    public init(debugDescription: String) {
        self.codingPath = []
        self.debugDescription = debugDescription
        self.underlyingError = nil
    }
}

extension DecodingError.Context {
    public init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
        self.debugDescription = ""
        self.underlyingError = nil
    }
    
    public init(debugDescription: String) {
        self.codingPath = []
        self.debugDescription = debugDescription
        self.underlyingError = nil
    }
}
