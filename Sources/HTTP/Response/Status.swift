public enum Status {
    case `continue`
    case switchingProtocols
    case processing
    
    case ok
    case created
    case accepted
    case nonAuthoritativeInformation
    case noContent
    case resetContent
    case partialContent
    
    case multipleChoices
    case movedPermanently
    case found
    case seeOther
    case notModified
    case useProxy
    case switchProxy
    case temporaryRedirect
    case permanentRedirect
    
    case badRequest
    case unauthorized
    case paymentRequired
    case forbidden
    case notFound
    case methodNotAllowed
    case notAcceptable
    case proxyAuthenticationRequired
    case requestTimeout
    case conflict
    case gone
    case lengthRequired
    case preconditionFailed
    case requestEntityTooLarge
    case requestURITooLong
    case unsupportedMediaType
    case requestedRangeNotSatisfiable
    case expectationFailed
    case imATeapot
    case authenticationTimeout
    case enhanceYourCalm
    case unprocessableEntity
    case locked
    case failedDependency
    case preconditionRequired
    case tooManyRequests
    case requestHeaderFieldsTooLarge
    
    case internalServerError
    case notImplemented
    case badGateway
    case serviceUnavailable
    case gatewayTimeout
    case httpVersionNotSupported
    case variantAlsoNegotiates
    case insufficientStorage
    case loopDetected
    case notExtended
    case networkAuthenticationRequired
    
    case other(statusCode: Int, reasonPhrase: String)
}

extension Status {
    public var isInformational: Bool {
        return (100 ..< 200).contains(statusCode)
    }

    public var isSuccessful: Bool {
        return (200 ..< 300).contains(statusCode)
    }

    public var isRedirection: Bool {
        return (300 ..< 400).contains(statusCode)
    }

    public var isError: Bool {
        return (400 ..< 600).contains(statusCode)
    }

    public var isClientError: Bool {
        return (400 ..< 500).contains(statusCode)
    }

    public var isServerError: Bool {
        return (500 ..< 600).contains(statusCode)
    }
}

extension Status : Hashable {
    public var hashValue: Int {
        return statusCode
    }
}

extension Status: Equatable {
    public static func ==(lhs: Status, rhs: Status) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension Status {
    public init(statusCode: Int, reasonPhrase: String? = nil) {
        if let reasonPhrase = reasonPhrase {
            self = .other(statusCode: statusCode, reasonPhrase: reasonPhrase)
        } else {
            switch statusCode {
            case Status.continue.statusCode:                      self = .continue
            case Status.switchingProtocols.statusCode:            self = .switchingProtocols
            case Status.processing.statusCode:                    self = .processing

            case Status.ok.statusCode:                            self = .ok
            case Status.created.statusCode:                       self = .created
            case Status.accepted.statusCode:                      self = .accepted
            case Status.nonAuthoritativeInformation.statusCode:   self = .nonAuthoritativeInformation
            case Status.noContent.statusCode:                     self = .noContent
            case Status.resetContent.statusCode:                  self = .resetContent
            case Status.partialContent.statusCode:                self = .partialContent

            case Status.multipleChoices.statusCode:               self = .multipleChoices
            case Status.movedPermanently.statusCode:              self = .movedPermanently
            case Status.found.statusCode:                         self = .found
            case Status.seeOther.statusCode:                      self = .seeOther
            case Status.notModified.statusCode:                   self = .notModified
            case Status.useProxy.statusCode:                      self = .useProxy
            case Status.switchProxy.statusCode:                   self = .switchProxy
            case Status.temporaryRedirect.statusCode:             self = .temporaryRedirect
            case Status.permanentRedirect.statusCode:             self = .permanentRedirect

            case Status.badRequest.statusCode:                    self = .badRequest
            case Status.unauthorized.statusCode:                  self = .unauthorized
            case Status.paymentRequired.statusCode:               self = .paymentRequired
            case Status.forbidden.statusCode:                     self = .forbidden
            case Status.notFound.statusCode:                      self = .notFound
            case Status.methodNotAllowed.statusCode:              self = .methodNotAllowed
            case Status.notAcceptable.statusCode:                 self = .notAcceptable
            case Status.proxyAuthenticationRequired.statusCode:   self = .proxyAuthenticationRequired
            case Status.requestTimeout.statusCode:                self = .requestTimeout
            case Status.conflict.statusCode:                      self = .conflict
            case Status.gone.statusCode:                          self = .gone
            case Status.lengthRequired.statusCode:                self = .lengthRequired
            case Status.preconditionFailed.statusCode:            self = .preconditionFailed
            case Status.requestEntityTooLarge.statusCode:         self = .requestEntityTooLarge
            case Status.requestURITooLong.statusCode:             self = .requestURITooLong
            case Status.unsupportedMediaType.statusCode:          self = .unsupportedMediaType
            case Status.requestedRangeNotSatisfiable.statusCode:  self = .requestedRangeNotSatisfiable
            case Status.expectationFailed.statusCode:             self = .expectationFailed
            case Status.imATeapot.statusCode:                     self = .imATeapot
            case Status.authenticationTimeout.statusCode:         self = .authenticationTimeout
            case Status.enhanceYourCalm.statusCode:               self = .enhanceYourCalm
            case Status.unprocessableEntity.statusCode:           self = .unprocessableEntity
            case Status.locked.statusCode:                        self = .locked
            case Status.failedDependency.statusCode:              self = .failedDependency
            case Status.preconditionRequired.statusCode:          self = .preconditionRequired
            case Status.tooManyRequests.statusCode:               self = .tooManyRequests
            case Status.requestHeaderFieldsTooLarge.statusCode:   self = .requestHeaderFieldsTooLarge

            case Status.internalServerError.statusCode:           self = .internalServerError
            case Status.notImplemented.statusCode:                self = .notImplemented
            case Status.badGateway.statusCode:                    self = .badGateway
            case Status.serviceUnavailable.statusCode:            self = .serviceUnavailable
            case Status.gatewayTimeout.statusCode:                self = .gatewayTimeout
            case Status.httpVersionNotSupported.statusCode:       self = .httpVersionNotSupported
            case Status.variantAlsoNegotiates.statusCode:         self = .variantAlsoNegotiates
            case Status.insufficientStorage.statusCode:           self = .insufficientStorage
            case Status.loopDetected.statusCode:                  self = .loopDetected
            case Status.notExtended.statusCode:                   self = .notExtended
            case Status.networkAuthenticationRequired.statusCode: self = .networkAuthenticationRequired

            default: self = .other(statusCode: statusCode, reasonPhrase: "CUSTOM")
            }
        }
    }
}

extension Status {
    public var statusCode: Int {
        switch self {
        case .continue:                      return 100
        case .switchingProtocols:            return 101
        case .processing:                    return 102

        case .ok:                            return 200
        case .created:                       return 201
        case .accepted:                      return 202
        case .nonAuthoritativeInformation:   return 203
        case .noContent:                     return 204
        case .resetContent:                  return 205
        case .partialContent:                return 206

        case .multipleChoices:               return 300
        case .movedPermanently:              return 301
        case .found:                         return 302
        case .seeOther:                      return 303
        case .notModified:                   return 304
        case .useProxy:                      return 305
        case .switchProxy:                   return 306
        case .temporaryRedirect:             return 307
        case .permanentRedirect:             return 308

        case .badRequest:                    return 400
        case .unauthorized:                  return 401
        case .paymentRequired:               return 402
        case .forbidden:                     return 403
        case .notFound:                      return 404
        case .methodNotAllowed:              return 405
        case .notAcceptable:                 return 406
        case .proxyAuthenticationRequired:   return 407
        case .requestTimeout:                return 408
        case .conflict:                      return 409
        case .gone:                          return 410
        case .lengthRequired:                return 411
        case .preconditionFailed:            return 412
        case .requestEntityTooLarge:         return 413
        case .requestURITooLong:             return 414
        case .unsupportedMediaType:          return 415
        case .requestedRangeNotSatisfiable:  return 416
        case .expectationFailed:             return 417
        case .imATeapot:                     return 418
        case .authenticationTimeout:         return 419
        case .enhanceYourCalm:               return 420
        case .unprocessableEntity:           return 422
        case .locked:                        return 423
        case .failedDependency:              return 424
        case .preconditionRequired:          return 428
        case .tooManyRequests:               return 429
        case .requestHeaderFieldsTooLarge:   return 431

        case .internalServerError:           return 500
        case .notImplemented:                return 501
        case .badGateway:                    return 502
        case .serviceUnavailable:            return 503
        case .gatewayTimeout:                return 504
        case .httpVersionNotSupported:       return 505
        case .variantAlsoNegotiates:         return 506
        case .insufficientStorage:           return 507
        case .loopDetected:                  return 508
        case .notExtended:                   return 510
        case .networkAuthenticationRequired: return 511

        case .other(let statusCode, _):        return statusCode
        }
    }
    
    public var statusCodeString: String {
        switch self {
        case .continue:                      return "100"
        case .switchingProtocols:            return "101"
        case .processing:                    return "102"
            
        case .ok:                            return "200"
        case .created:                       return "201"
        case .accepted:                      return "202"
        case .nonAuthoritativeInformation:   return "203"
        case .noContent:                     return "204"
        case .resetContent:                  return "205"
        case .partialContent:                return "206"
            
        case .multipleChoices:               return "300"
        case .movedPermanently:              return "301"
        case .found:                         return "302"
        case .seeOther:                      return "303"
        case .notModified:                   return "304"
        case .useProxy:                      return "305"
        case .switchProxy:                   return "306"
        case .temporaryRedirect:             return "307"
        case .permanentRedirect:             return "308"
            
        case .badRequest:                    return "400"
        case .unauthorized:                  return "401"
        case .paymentRequired:               return "402"
        case .forbidden:                     return "403"
        case .notFound:                      return "404"
        case .methodNotAllowed:              return "405"
        case .notAcceptable:                 return "406"
        case .proxyAuthenticationRequired:   return "407"
        case .requestTimeout:                return "408"
        case .conflict:                      return "409"
        case .gone:                          return "410"
        case .lengthRequired:                return "411"
        case .preconditionFailed:            return "412"
        case .requestEntityTooLarge:         return "413"
        case .requestURITooLong:             return "414"
        case .unsupportedMediaType:          return "415"
        case .requestedRangeNotSatisfiable:  return "416"
        case .expectationFailed:             return "417"
        case .imATeapot:                     return "418"
        case .authenticationTimeout:         return "419"
        case .enhanceYourCalm:               return "420"
        case .unprocessableEntity:           return "422"
        case .locked:                        return "423"
        case .failedDependency:              return "424"
        case .preconditionRequired:          return "428"
        case .tooManyRequests:               return "429"
        case .requestHeaderFieldsTooLarge:   return "431"
            
        case .internalServerError:           return "500"
        case .notImplemented:                return "501"
        case .badGateway:                    return "502"
        case .serviceUnavailable:            return "503"
        case .gatewayTimeout:                return "504"
        case .httpVersionNotSupported:       return "505"
        case .variantAlsoNegotiates:         return "506"
        case .insufficientStorage:           return "507"
        case .loopDetected:                  return "508"
        case .notExtended:                   return "510"
        case .networkAuthenticationRequired: return "511"
            
        case .other(let statusCode, _):        return statusCode.description
        }
    }
}

extension Status {
    public var reasonPhrase: String {
        switch self {
        case .continue:                      return "Continue"
        case .switchingProtocols:            return "Switching Protocols"
        case .processing:                    return "Processing"

        case .ok:                            return "OK"
        case .created:                       return "Created"
        case .accepted:                      return "Accepted"
        case .nonAuthoritativeInformation:   return "Non Authoritative Information"
        case .noContent:                     return "No Content"
        case .resetContent:                  return "Reset Content"
        case .partialContent:                return "Partial Content"

        case .multipleChoices:               return "Multiple Choices"
        case .movedPermanently:              return "Moved Permanently"
        case .found:                         return "Found"
        case .seeOther:                      return "See Other"
        case .notModified:                   return "Not Modified"
        case .useProxy:                      return "Use Proxy"
        case .switchProxy:                   return "Switch Proxy"
        case .temporaryRedirect:             return "Temporary Redirect"
        case .permanentRedirect:             return "Permanent Redirect"

        case .badRequest:                    return "Bad Request"
        case .unauthorized:                  return "Unauthorized"
        case .paymentRequired:               return "Payment Required"
        case .forbidden:                     return "Forbidden"
        case .notFound:                      return "Not Found"
        case .methodNotAllowed:              return "Method Not Allowed"
        case .notAcceptable:                 return "Not Acceptable"
        case .proxyAuthenticationRequired:   return "Proxy Authentication Required"
        case .requestTimeout:                return "Request Timeout"
        case .conflict:                      return "Conflict"
        case .gone:                          return "Gone"
        case .lengthRequired:                return "Length Required"
        case .preconditionFailed:            return "Precondition Failed"
        case .requestEntityTooLarge:         return "Request Entity Too Large"
        case .requestURITooLong:             return "Request URI Too Long"
        case .unsupportedMediaType:          return "Unsupported Media Type"
        case .requestedRangeNotSatisfiable:  return "Requested Range Not Satisfiable"
        case .expectationFailed:             return "Expectation Failed"
        case .imATeapot:                     return "I'm A Teapot"
        case .authenticationTimeout:         return "Authentication Timeout"
        case .enhanceYourCalm:               return "Enhance Your Calm"
        case .unprocessableEntity:           return "Unprocessable Entity"
        case .locked:                        return "Locked"
        case .failedDependency:              return "Failed Dependency"
        case .preconditionRequired:          return "Precondition Required"
        case .tooManyRequests:               return "Too Many Requests"
        case .requestHeaderFieldsTooLarge:   return "Request Header Fields Too Large"

        case .internalServerError:           return "Internal Server Error"
        case .notImplemented:                return "Not Implemented"
        case .badGateway:                    return "Bad Gateway"
        case .serviceUnavailable:            return "Service Unavailable"
        case .gatewayTimeout:                return "Gateway Timeout"
        case .httpVersionNotSupported:       return "HTTP Version Not Supported"
        case .variantAlsoNegotiates:         return "Variant Also Negotiates"
        case .insufficientStorage:           return "Insufficient Storage"
        case .loopDetected:                  return "Loop Detected"
        case .notExtended:                   return "Not Extended"
        case .networkAuthenticationRequired: return "Network Authentication Required"
        case .other(_, let reasonPhrase): return reasonPhrase
        }
    }
}

extension Status : CustomStringConvertible {
    public var description: String {
        return statusCodeString + " " + reasonPhrase
    }
}
