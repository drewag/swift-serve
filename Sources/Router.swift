//
//  Router.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

public enum ResponseStatus {
    case unhandled
    case handled(Response)
}

public protocol Router {
    var routes: [Route] {get}
}

extension Router {
    public func route(request: Request, to path: String) throws -> ResponseStatus {
        let path = self.fix(path: path)

        for route in self.routes {
            if route.pathComponent.matches(path: path, using: request.method) {
                let response = try route.route(request: request, to: path)
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

    private func fix(path: String) -> String {
        guard path.hasPrefix("/") else {
            return path
        }

        var output = ""
        for (index, character) in path.enumerated() {
            guard index != 0 else {
                continue
            }
            output.append(character)
        }
        return output
    }

}

struct InPlaceRouter: Router {
    let routes: [Route]
}
