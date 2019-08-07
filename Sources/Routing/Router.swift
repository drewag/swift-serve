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

    func preprocess(request: Request, context: inout [String:Any]) throws
    func postprocess(request: Request, context: inout [String:Any]) throws
}

extension Router {
    public func preprocess(request: Request, context: inout [String:Any]) throws {}
    public func postprocess(request: Request, context: inout [String:Any]) throws {}

    public func route(request: Request, to path: String) throws -> ResponseStatus {
        let path = self.fix(path: path)

        var request = request
        request.preprocessStack.append(self.preprocess)
        request.postprocessStack.append(self.postprocess)

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
        var lastWasSlash = false
        for (index, character) in path.enumerated() {
            guard index != 0 else {
                continue
            }
            guard !lastWasSlash || (character != "/") else {
                continue
            }
            output.append(character)
            lastWasSlash = character == "/"
        }
        return output
    }
}

struct InPlaceRouter: Router {
    let routes: [Route]
}
