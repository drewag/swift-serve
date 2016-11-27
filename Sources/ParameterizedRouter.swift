//
//  ParameterizedRouter.swift
//  web
//
//  Created by Andrew J Wagner on 11/24/16.
//
//

public protocol ParameterizedRouter {
    associatedtype Param: CapturableType

    var routes: [ParameterizedRoute<Param>] {get}
}

extension ParameterizedRouter {
    public func route(request: Request, pathParameter: Param, to path: String) throws -> ResponseStatus {
        for route in self.routes {
            if route.pathComponent.matches(path: path, using: request.method) {
                let response = try route.route(request: request, param: pathParameter, to: path)
                switch response {
                case .handled(_):
                    return response
                case .unhandled:
                    break
                }
            }
        }
        return .unhandled
    }
}
