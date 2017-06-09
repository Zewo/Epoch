// Copyright (c) 2015, Kyle Fuller
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// * Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// * Neither the name of Mockingjay nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Foundation

public enum JSONType : String {
    case object = "object"
    case array = "array"
    case string = "string"
    case integer = "integer"
    case number = "number"
    case boolean = "boolean"
    case null = "null"
}

public enum ValidationResult {
    case valid
    case invalid([String])
    
    public var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    public var errors: [String] {
        switch self {
        case .valid:
            return []
        case .invalid(let errors):
            return errors
        }
    }
}

typealias Validate = (JSON) -> ValidationResult

extension JSON {
    public struct Schema {
        public let title: String?
        public let description: String?
        
        public let type: [JSONType]?
        
        let formats: [String: Validate]
        
        let schema: JSON
        
        public init(_ schema: JSON) {
            title = try? schema.get("title")
            description = try? schema.get("description")
            
            if let type = try? schema.get("type") as String {
                if let type = JSONType(rawValue: type) {
                    self.type = [type]
                } else {
                    self.type = []
                }
            } else if let types = try? schema.get("type") as [String] {
                self.type = types.map { JSONType(rawValue: $0) }.filter { $0 != nil }.map { $0! }
            } else {
                self.type = []
            }
            
            self.schema = schema
            
            formats = [
                "ipv4": validateIPv4,
                "ipv6": validateIPv6,
            ]
        }
        
        public func validate(_ data: JSON) -> ValidationResult {
            let validate = allOf(getValidators(self)(schema))
            return validate(data)
        }
        
        func validatorForReference(_ reference: String) -> Validate {
            if let reference = reference.stringByRemovingPrefix("#") {  // Document relative
                if
                    let tmp = reference.stringByRemovingPrefix("/"),
                    let reference = tmp.removingPercentEncoding
                {
                    var components = reference.components(separatedBy: "/")
                    var schema = self.schema
                    
                    while let component = components.first {
                        components.remove(at: components.startIndex)
                        
                        if let _ = try? schema.get(component) as [String: JSON] {
                            schema = try! schema.get(component) as JSON
                            continue
                        } else if let _ = try? schema.get(component) as [[String: JSON]] {
                            let schemas = try! schema.get(component) as [JSON]
                            
                            if let component = components.first, let index = Int(component) {
                                components.remove(at: components.startIndex)
                                
                                if schemas.count > index {
                                    schema = schemas[index]
                                    continue
                                }
                            }
                        }
                        
                        return invalidValidation("Reference not found '\(component)' in '\(reference)'")
                    }
                    
                    return allOf(getValidators(self)(schema))
                } else if reference == "" {
                    return { value in
                        let validators = getValidators(self)(self.schema)
                        return allOf(validators)(value)
                    }
                }
            }
            
            return invalidValidation("Remote $ref '\(reference)' is not yet supported")
        }
    }
}

/// Returns a set of validators for a schema and document
func getValidators(_ root: JSON.Schema) -> (_ schema: JSON) -> [Validate] {
    return { schema in
        var validators: [Validate] = []
        
        if let ref = try? schema.get("$ref") as String {
            validators.append(root.validatorForReference(ref))
        }
        
        if let type = try? schema.get("type") as String {
            validators.append(validateType(type))
        }
        
        if let _ = try? schema.get("allOf") as [[String: JSON]] {
            let allOf = try! schema.get("allOf") as [JSON]
            validators += allOf.map(getValidators(root)).reduce([], +)
        }
        
        if let _ = try? schema.get("anyOf") as [[String: JSON]] {
            let anyOfSchemas = try! schema.get("anyOf") as [JSON]
            let anyOfValidators = anyOfSchemas.map(getValidators(root)).map(allOf) as [Validate]
            validators.append(anyOf(anyOfValidators))
        }

        if let _ = try? schema.get("oneOf") as [[String: JSON]] {
            let oneOfSchemas = try! schema.get("oneOf") as [JSON]
            let oneOfValidators = oneOfSchemas.map(getValidators(root)).map(allOf) as [Validate]
            validators.append(oneOf(oneOfValidators))
        }
        
        if let _ = try? schema.get("not") as [String: JSON] {
            let notSchema = try! schema.get("not") as JSON
            let notValidator = allOf(getValidators(root)(notSchema))
            validators.append(not(notValidator))
        }
        
        if let enumValues = try? schema.get("enum") as [JSON] {
            validators.append(validateEnum(enumValues))
        }
        
        // String
        
        if let maxLength = try? schema.get("maxLength") as Int {
            validators.append(
                validateLength(
                    <=,
                    length: maxLength,
                    error: "Length of string is larger than max length \(maxLength)"
                )
            )
        }
        
        if let minLength = try? schema.get("minLength") as Int {
            validators.append(
                validateLength(
                    >=,
                    length: minLength,
                    error: "Length of string is smaller than minimum length \(minLength)"
                )
            )
        }
        
        if let pattern = try? schema.get("pattern") as String {
            validators.append(validatePattern(pattern))
        }
        
        // Numerical
        
        if let multipleOf = try? schema.get("multipleOf") as Double {
            validators.append(validateMultipleOf(multipleOf))
        }
        
        if let minimum = try? schema.get("minimum") as Double {
            validators.append(
                validateNumericLength(
                    minimum,
                    comparator: >=,
                    exclusiveComparitor: >,
                    exclusive: try? schema.get("exclusiveMinimum") as Bool,
                    error: "Value is lower than minimum value of \(minimum)"
                )
            )
        }

        if let maximum = try? schema.get("maximum") as Double {
            validators.append(
                validateNumericLength(
                    maximum,
                    comparator: <=,
                    exclusiveComparitor: <,
                    exclusive: try? schema.get("exclusiveMaximum") as Bool,
                    error: "Value exceeds maximum value of \(maximum)"
                )
            )
        }
        
        // Array
        
        if let minItems = try? schema.get("minItems") as Int {
            validators.append(
                validateArrayLength(
                    minItems,
                    comparator: >=,
                    error: "Length of array is smaller than the minimum \(minItems)"
                )
            )
        }
        
        if let maxItems = try? schema.get("maxItems") as Int {
            validators.append(
                validateArrayLength(
                    maxItems,
                    comparator: <=,
                    error: "Length of array is greater than maximum \(maxItems)"
                )
            )
        }
        
//        if let uniqueItems = try? schema.get("uniqueItems") as Bool {
//            if uniqueItems {
//                validators.append(validateUniqueItems)
//            }
//        }
        
        if let _ = try? schema.get("items") as [String: JSON] {
            let items = try! schema.get("items") as JSON
            let itemsValidators = allOf(getValidators(root)(items))
            validators.append(validateItems(itemsValidators))
        } else if let _ = try? schema.get("items") as [[String: JSON]] {
            func createAdditionalItemsValidator(_ additionalItems: JSON?) -> Validate {
                if let items = additionalItems, let _ = try? items.get() as [String: JSON] {
                    let additionalItems = try! additionalItems!.get() as JSON
                    return allOf(getValidators(root)(additionalItems))
                }
                
                let additionalItems = additionalItems.flatMap({ try? $0.get() as Bool }) ?? true
                
                if additionalItems {
                    return validValidation
                }
                
                return invalidValidation("Additional results are not permitted in this array.")
            }
            
            let additionalItemsValidator = createAdditionalItemsValidator(
                try? schema.get("additionalItems")
            )
            
            let items = try! schema.get("items") as [JSON]
            let itemValidators = items.map(getValidators(root))
            
            func validateItems(_ value: JSON) -> ValidationResult {
                if let value = try? value.get() as [JSON] {
                    var results: [ValidationResult] = []
                    
                    for (index, element) in value.enumerated() {
                        if index >= itemValidators.count {
                            results.append(additionalItemsValidator(element))
                        } else {
                            let validators = allOf(itemValidators[index])
                            results.append(validators(element))
                        }
                    }
                    
                    return flatten(results)
                }
                
                return .valid
            }
            
            validators.append(validateItems)
        }
        
        if let maxProperties = try? schema.get("maxProperties") as Int {
            validators.append(
                validatePropertiesLength(
                    maxProperties,
                    comparator: >=,
                    error: "Amount of properties is greater than maximum permitted"
                )
            )
        }
        
        if let minProperties = try? schema.get("minProperties") as Int {
            validators.append(
                validatePropertiesLength(
                    minProperties,
                    comparator: <=,
                    error: "Amount of properties is less than the required amount"
                )
            )
        }
        
        if let required = try? schema.get("required") as [String] {
            validators.append(validateRequired(required))
        }
        
//        let properties = try? schema.get("properties")
//        let patternProperties = try? schema.get("patternProperties")
//        let additionalProperties = try? schema.get("additionalProperties")
//        
//        if
//            properties != nil ||
//            patternProperties != nil ||
//            additionalProperties != nil
//        {
//            func createAdditionalPropertiesValidator(_ additionalProperties: JSON?) -> Validate {
//                if let additionalProperties = additionalProperties as? [String: JSON] {
//                    return allOf(getValidators(root)(additionalProperties))
//                }
//                
//                let additionalProperties = additionalProperties as? Bool ?? true
//                
//                if additionalProperties {
//                    return validValidation
//                }
//                
//                return invalidValidation("Additional properties are not permitted in this object.")
//            }
//            
//            func createPropertiesValidators(_ properties:[String:[String:Any]]?) -> [String: Validate]? {
//                if let properties = properties {
//                    return Dictionary(properties.keys.map {
//                        key in (key, allOf(JSONSchema.validators(root)(properties[key]!)))
//                    })
//                }
//                
//                return nil
//            }
//            
//            let additionalPropertyValidator = createAdditionalPropertiesValidator(schema["additionalProperties"])
//            let properties = createPropertiesValidators(schema["properties"] as? [String:[String:Any]])
//            let patternProperties = createPropertiesValidators(schema["patternProperties"] as? [String:[String:Any]])
//            validators.append(validateProperties(properties, patternProperties: patternProperties, additionalProperties: additionalPropertyValidator))
//        }
        
        if let dependencies = try? schema.get("dependencies") as [String: JSON] {
            for (key, dependencies) in dependencies {
                if let _ = try? dependencies.get() as [String: JSON] {
                    let dependencies = try! dependencies.get() as JSON
                    let schema = allOf(getValidators(root)(dependencies))
                    validators.append(validateDependency(key, validator: schema))
                } else if let dependencies = try? dependencies.get() as [String] {
                    validators.append(validateDependencies(key, dependencies: dependencies))
                }
            }
        }

        if let format = try? schema.get("format") as String {
            if let validator = root.formats[format] {
                validators.append(validator)
            } else {
                validators.append(
                    invalidValidation("'format' validation of '\(format)' is not yet supported.")
                )
            }
        }
        
        return validators
    }
}

public func validate(_ value: JSON, schema: [String: JSON]) -> ValidationResult {
    let schema = JSON(schema)
    let root = JSON.Schema(schema)
    let validator = allOf(getValidators(root)(schema))
    let result = validator(value)
    return result
}

/// Extension for dictionary providing initialization from array of elements
extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        
        for (key, value) in pairs {
            self[key] = value
        }
    }
}

/// Flatten an array of results into a single result (combining all errors)
func flatten(_ results:[ValidationResult]) -> ValidationResult {
    let failures = results.filter({ result in !result.isValid })
    
    if failures.count > 0 {
        let errors: [String] = failures.reduce([]) { (accumulator, failure) in
            return accumulator + failure.errors
        }
        
        return .invalid(errors)
    }
    
    return .valid
}

/// Creates a Validator which always returns an valid result
func validValidation(_ value: JSON) -> ValidationResult {
    return .valid
}

/// Creates a Validator which always returns an invalid result with the given error
func invalidValidation(_ error: String) -> (_ value: JSON) -> ValidationResult {
    return { value in
        return .invalid([error])
    }
}

// MARK: Shared
/// Validate the given value is of the given type
func validateType(_ type: String) -> (_ value: JSON) -> ValidationResult {
    return { value in
        switch type {
        case "integer":
            if value.isInt {
                return .valid
            }
        case "number":
            if value.isInt || value.isDouble {
                return .valid
            }
        case "string":
            if value.isString {
                return .valid
            }
        case "object":
            if value.isObject {
                return .valid
            }
        case "array":
            if value.isArray {
                return .valid
            }
        case "boolean":
            if value.isBool {
                return .valid
            }
        case "null":
            if value.isNull {
                return .valid
            }
        default:
            break
        }
        
        return .invalid(["'\(value)' is not of type '\(type)'"])
    }
}

///// Validate the given value is one of the given types
//func validateType(_ type:[String]) -> Validator {
//    let typeValidators = type.map(validateType) as [Validator]
//    return anyOf(typeValidators)
//}
//
//func validateType(_ type:Any) -> Validator {
//    if let type = type as? String {
//        return validateType(type)
//    } else if let types = type as? [String] {
//        return validateType(types)
//    }
//    
//    return invalidValidation("'\(type)' is not a valid 'type'")
//}


/// Validate that a value is valid for any of the given validation rules
func anyOf(_ validators: [Validate], error: String? = nil) -> (_ value: JSON) -> ValidationResult {
    return { value in
        for validator in validators {
            let result = validator(value)
            
            if result.isValid {
                return .valid
            }
        }
        
        if let error = error {
            return .invalid([error])
        }
        
        return .invalid(["\(value) does not meet anyOf validation rules."])
    }
}

func oneOf(_ validators: [Validate]) -> (_ value: JSON) -> ValidationResult {
    return { value in
        let results = validators.map({ validator in validator(value) })
        let validValidators = results.filter({ $0.isValid }).count
        
        if validValidators == 1 {
            return .valid
        }
        
        return .invalid(["\(validValidators) validates instead `oneOf`."])
    }
}

/// Creates a validator that validates that the given validation rules are not met
func not(_ validator: @escaping Validate) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if validator(value).isValid {
            return .invalid(["'\(value)' does not match 'not' validation."])
        }
        
        return .valid
    }
}

func allOf(_ validators: [Validate]) -> (_ value: JSON) -> ValidationResult {
    return { value in
        return flatten(validators.map { validator in validator(value) })
    }
}

func validateEnum(_ values: [JSON]) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if values.contains(value) {
            return .valid
        }
        
        return .invalid(["'\(value)' is not a valid enumeration value of '\(values)'"])
    }
}

// MARK: String

func validateLength(
    _ comparator: @escaping ((Int, Int) -> (Bool)),
    length: Int,
    error: String
) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let value = try? value.get() as String {
            if !comparator(value.characters.count, length) {
                return .invalid([error])
            }
        }
        
        // TODO: Maybe this should be an error?
        return .valid
    }
}

func validatePattern(_ pattern: String) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let value = try? value.get() as String {
            let expression = try? NSRegularExpression(
                pattern: pattern,
                options: []
            )
            
            if let expression = expression {
                let range = NSMakeRange(0, value.characters.count)
                
                if expression.matches(in: value, options: [], range: range).count == 0 {
                    return .invalid(["'\(value)' does not match pattern: '\(pattern)'"])
                }
            } else {
                return .invalid(["[Schema] Regex pattern '\(pattern)' is not valid"])
            }
        }
        
        return .valid
    }
}

//// MARK: Numerical

func validateMultipleOf(_ number: Double) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if number > 0.0 {
            if let value = try? value.get() as Double {
                let result = value / number
                
                if result != floor(result) {
                    return .invalid(["\(value) is not a multiple of \(number)"])
                }
            }
        }
        
        return .valid
    }
}

func validateNumericLength(
    _ length: Double,
    comparator: @escaping ((Double, Double) -> (Bool)),
    exclusiveComparitor: @escaping ((Double, Double) -> (Bool)),
    exclusive: Bool?,
    error: String
) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let value = try? value.get() as Double {
            if exclusive ?? false {
                if !exclusiveComparitor(value, length) {
                    return .invalid([error])
                }
            }
            
            if !comparator(value, length) {
                return .invalid([error])
            }
        }
        
        return .valid
    }
}

//// MARK: Array

func validateArrayLength(
    _ rhs: Int,
    comparator: @escaping ((Int, Int) -> Bool),
    error: String
) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let value = try? value.get() as [JSON] {
            if !comparator(value.count, rhs) {
                return .invalid([error])
            }
        }
        
        return .valid
    }
}

// MARK: object

func validatePropertiesLength(
    _ length: Int,
    comparator: @escaping ((Int, Int) -> (Bool)),
    error: String
) -> (_ value: JSON)  -> ValidationResult {
    return { value in
        if let value = try? value.get() as [String: JSON] {
            if !comparator(length, value.count) {
                return .invalid([error])
            }
        }
        
        return .valid
    }
}

func validateRequired(_ required: [String]) -> (_ value: JSON)  -> ValidationResult {
    return { value in
        if let value = try? value.get() as [String: JSON] {
            if (required.filter { r in !value.keys.contains(r) }.count == 0) {
                return .valid
            }
            
            return .invalid(["Required properties are missing '\(required)'"])
        }
        
        return .valid
    }
}

func validateDependency(
    _ key: String,
    validator: @escaping Validate
) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let object = try? value.get() as [String: JSON] {
            if object[key] != nil {
                return validator(value)
            }
        }
        
        return .valid
    }
}

func validateDependencies(
    _ key: String,
    dependencies: [String]
) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let value = try? value.get() as [String: JSON] {
            if value[key] != nil {
                return flatten(dependencies.map { dependency in
                    if value[dependency] == nil {
                        return .invalid(["'\(key)' is missing it's dependency of '\(dependency)'"])
                    }
                    
                    return .valid
                })
            }
        }

        return .valid
    }
}

func validateItems(
    _ itemsValidators: @escaping (JSON) -> ValidationResult
) -> (_ value: JSON) -> ValidationResult {
    return { value in
        if let document = try? value.get() as [JSON] {
            return flatten(document.map(itemsValidators))
        }
        
        return .valid
    }
}

//func validateProperties(_ properties: [String:Validator]?, patternProperties: [String:Validator]?, additionalProperties: Validator?) -> (_ value: Any) -> ValidationResult {
//    return { value in
//        if let value = value as? [String:Any] {
//            let allKeys = NSMutableSet()
//            var results = [ValidationResult]()
//            
//            if let properties = properties {
//                for (key, validator) in properties {
//                    allKeys.add(key)
//                    
//                    if let value: Any = value[key] {
//                        results.append(validator(value))
//                    }
//                }
//            }
//            
//            if let patternProperties = patternProperties {
//                for (pattern, validator) in patternProperties {
//                    do {
//                        let expression = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
//                        let keys = value.keys.filter {
//                            (key: String) in expression.matches(in: key, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, key.characters.count)).count > 0
//                        }
//                        
//                        allKeys.addObjects(from: Array(keys))
//                        results += keys.map { key in validator(value[key]!) }
//                    } catch {
//                        return .invalid(["[Schema] '\(pattern)' is not a valid regex pattern for patternProperties"])
//                    }
//                }
//            }
//            
//            if let additionalProperties = additionalProperties {
//                let additionalKeys = value.keys.filter { !allKeys.contains($0) }
//                results += additionalKeys.map { key in additionalProperties(value[key]!) }
//            }
//            
//            return flatten(results)
//        }
//        
//        return .Valid
//    }
//}
//
//func validateDependency(_ key: String, validator: @escaping LegacyValidator) -> (_ value: Any) -> Bool {
//    return { value in
//        if let value = value as? [String:Any] {
//            if (value[key] != nil) {
//                return validator(value as Any)
//            }
//        }
//        
//        return true
//    }
//}
//
//func validateDependencies(_ key: String, dependencies: [String]) -> (_ value: Any) -> Bool {
//    return { value in
//        if let value = value as? [String:Any] {
//            if (value[key] != nil) {
//                for dependency in dependencies {
//                    if (value[dependency] == nil) {
//                        return false
//                    }
//                }
//            }
//        }
//        
//        return true
//    }
//}

// MARK: Format

func validateIPv4(_ value:Any) -> ValidationResult {
    if let ipv4 = value as? String {
        if let expression = try? NSRegularExpression(
            pattern: "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$",
            options: []
        ) {
            if expression.matches(in: ipv4, options: [], range: NSMakeRange(0, ipv4.characters.count)).count == 1 {
                return .valid
            }
        }
        
        return .invalid(["'\(ipv4)' is not valid IPv4 address."])
    }
    
    return .valid
}

func validateIPv6(_ value:Any) -> ValidationResult {
    if let ipv6 = value as? String {
        var buf = UnsafeMutablePointer<Int8>.allocate(capacity: Int(INET6_ADDRSTRLEN))
        
        if inet_pton(AF_INET6, ipv6, &buf) == 1 {
            return .valid
        }
        
        return .invalid(["'\(ipv6)' is not valid IPv6 address."])
    }
    
    return .valid
}

extension String {
    func stringByRemovingPrefix(_ prefix: String) -> String? {
        if hasPrefix(prefix) {
            let index = characters.index(startIndex, offsetBy: prefix.characters.count)
            return substring(from: index)
        }
        
        return nil
    }
}
