import Core

public protocol ResponseRepresentable {
    var response: Response { get }
}

extension ParametersError : ResponseRepresentable {
    public var response: Response {
        switch self {
        case .parameterNotFound:
            return Response(status: .badRequest)
        case .cannotInitializeParameter:
            return Response(status: .badRequest)
        case .cannotInitializeParameters:
            return Response(status: .badRequest)
        }
    }
}
