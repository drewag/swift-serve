//
//  Route.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

public class Route {
    let pathComponent: PathComponent

    init(pathComponent: PathComponent) {
        self.pathComponent = pathComponent
    }

    func route(request: Request, to path: String) throws -> RouterResponse {
        fatalError("Must Override")
    }
}

extension Route {
    public static func any(_ path: String? = nil, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .any, handler: handler)
    }

    public static func any(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .any, router: router)
    }

    public static func anyWithParam<Param: CapturableType>(handleAllSubPaths: Bool, handler: @escaping (Request, Param) throws -> RouterResponse) -> Route {
        return VariableRoute<Param>(method: .any, handleAllSubPaths: handleAllSubPaths, handler: handler)
    }

    public static func get(_ path: String? = nil, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .get, handler: handler)
    }

    public static func get(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .get, router: router)
    }

    public static func getWithParam<Param: CapturableType>(handleAllSubPaths: Bool, handler: @escaping (Request, Param) throws -> RouterResponse) -> Route {
        return VariableRoute<Param>(method: .get, handleAllSubPaths: handleAllSubPaths, handler: handler)
    }

    public static func post(_ path: String? = nil, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .post, handler: handler)
    }

    public static func post(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .post, router: router)
    }

    public static func postWithParam<Param: CapturableType>(handleAllSubPaths: Bool, handler: @escaping (Request, Param) throws -> RouterResponse) -> Route {
        return VariableRoute<Param>(method: .post, handleAllSubPaths: handleAllSubPaths, handler: handler)
    }

    public static func put(_ path: String? = nil, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .put, handler: handler)
    }

    public static func put(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .put, router: router)
    }

    public static func putWithParam<Param: CapturableType>(handleAllSubPaths: Bool, handler: @escaping (Request, Param) throws -> RouterResponse) -> Route {
        return VariableRoute<Param>(method: .put, handleAllSubPaths: handleAllSubPaths, handler: handler)
    }
}

fileprivate class FixedHandlerRoute: Route {
    let handler: (Request) throws -> RouterResponse

    init(_ prefix: String?, method: HTTPMethod, handler: @escaping (Request) throws -> RouterResponse) {
        self.handler = handler
        if let prefix = prefix {
            super.init(pathComponent: StaticPathComponent(pattern: prefix, method: method, allowSubPaths: false))
        }
        else {
            super.init(pathComponent: AllPathComponent(method: method))
        }
    }

    public override func route(request: Request, to path: String) throws -> RouterResponse {
        return try self.handler(request)
    }
}

fileprivate class FixedRouterRoute: Route {
    let router: Router

    init(_ prefix: String?, method: HTTPMethod, router: Router) {
        self.router = router
        if let prefix = prefix {
            super.init(pathComponent: StaticPathComponent(pattern: prefix, method: method, allowSubPaths: true))
        }
        else {
            super.init(pathComponent: AllPathComponent(method: method))
        }
    }

    public override func route(request: Request, to path: String) throws -> RouterResponse {
        return try self.router.route(request: request, to: path)
    }
}

fileprivate final class VariableRoute<Param: CapturableType>: Route {
    let handler: (Request, Param) throws -> RouterResponse

    init(method: HTTPMethod, handleAllSubPaths: Bool, handler: @escaping (Request, Param) throws -> RouterResponse) {
        self.handler = handler
        let pathComponent = VariablePathComponent(type: Param.self, method: method, allowSubPaths: handleAllSubPaths)
        super.init(pathComponent: pathComponent)
    }

    public override func route(request: Request, to path: String) throws -> RouterResponse {
        let captureText = (self.pathComponent as! VariablePathComponent<Param>).captureText(fromPath: path)!
        return try self.handler(request, Param(fromCaptureText: captureText)!)
    }
}
