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

    func route(request: Request, to path: String) throws -> ResponseStatus {
        fatalError("Must Override")
    }
}

extension Route {
    public static func any(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return FixedHandlerRoute(path, method: .any, handler: handler)
    }

    public static func any(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .any, router: router)
    }

    public static func anyWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return VariableRoute<Param>(method: .any, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func anyWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route {
        return VariableRouterRoute<R>(method: .any, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func get(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return FixedHandlerRoute(path, method: .get, handler: handler)
    }

    public static func get(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .get, router: router)
    }

    public static func getWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return VariableRoute<Param>(method: .get, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func getWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route {
        return VariableRouterRoute<R>(method: .get, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func post(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return FixedHandlerRoute(path, method: .post, handler: handler)
    }

    public static func post(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .post, router: router)
    }

    public static func postWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return VariableRoute<Param>(method: .post, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func postWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route {
        return VariableRouterRoute<R>(method: .any, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func put(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return FixedHandlerRoute(path, method: .put, handler: handler)
    }

    public static func put(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .put, router: router)
    }

    public static func putWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return VariableRoute<Param>(method: .put, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func putWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route {
        return VariableRouterRoute<R>(method: .any, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func delete(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return FixedHandlerRoute(path, method: .delete, handler: handler)
    }

    public static func delete(_ path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: .delete, router: router)
    }

    public static func deleteWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return VariableRoute<Param>(method: .delete, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func deleteWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route {
        return VariableRouterRoute<R>(method: .any, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }
}

fileprivate class FixedHandlerRoute: Route {
    let handler: (Request) throws -> ResponseStatus

    init(_ prefix: String?, method: HTTPMethod, handler: @escaping (Request) throws -> ResponseStatus) {
        self.handler = handler
        if let prefix = prefix {
            super.init(pathComponent: StaticPathComponent(pattern: prefix, method: method, allowSubPaths: false))
        }
        else {
            super.init(pathComponent: AllPathComponent(method: method))
        }
    }

    public override func route(request: Request, to path: String) throws -> ResponseStatus {
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

    public override func route(request: Request, to path: String) throws -> ResponseStatus {
        let subPath = self.pathComponent.consume(path: path)
        return try self.router.route(request: request, to: subPath)
    }
}

fileprivate final class VariableRoute<Param: CapturableType>: Route {
    let handler: (Request, Param) throws -> ResponseStatus

    init(method: HTTPMethod, consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) {
        self.handler = handler
        let pathComponent = VariablePathComponent(type: Param.self, method: method, consumeEntireSubPath: consumeEntireSubPath)
        super.init(pathComponent: pathComponent)
    }

    public override func route(request: Request, to path: String) throws -> ResponseStatus {
        let captureText = (self.pathComponent as! VariablePathComponent<Param>).captureText(fromPath: path)!
        return try self.handler(request, Param(fromCaptureText: captureText)!)
    }
}

fileprivate final class VariableRouterRoute<R: ParameterizedRouter>: Route {
    let router: R

    init(method: HTTPMethod, consumeEntireSubPath: Bool, router: R) {
        self.router = router
        let pathComponent = VariablePathComponent(type: R.Param.self, method: method, consumeEntireSubPath: consumeEntireSubPath)
        super.init(pathComponent: pathComponent)
    }

    public override func route(request: Request, to path: String) throws -> ResponseStatus {
        let captureText = (self.pathComponent as! VariablePathComponent<R.Param>).captureText(fromPath: path)!
        let subPath = self.pathComponent.consume(path: path)
        return try self.router.route(request: request, pathParameter: R.Param(fromCaptureText: captureText)!, to: subPath)
    }
}
