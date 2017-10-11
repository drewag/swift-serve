//
//  Route.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Swiftlier

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
    // MARK: Generic

    public static func route(method: HTTPMethod, path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return FixedHandlerRoute(path, method: method, handler: handler)
    }

    public static func route(method: HTTPMethod, path: String? = nil, router: Router) -> Route {
        return FixedRouterRoute(path, method: method, router: router)
    }

    public static func route(method: HTTPMethod, path: String? = nil, subRoutes: [Route]) -> Route {
        let router = InPlaceRouter(routes: subRoutes)
        return self.route(method: method, path: path, router: router)
    }

    public static func routeWithParam<Param: CapturableType>(method: HTTPMethod, consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return VariableRoute<Param>(method: method, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func routeWithParam<R: ParameterizedRouter>(method: HTTPMethod, consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return VariableRouterRoute<R>(method: method, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func routeWithParam<Param>(method: HTTPMethod, consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.routeWithParam(method: method, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    // MARK: Any

    public static func any(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return self.route(method: .any, path: path, handler: handler)
    }

    public static func any(_ path: String? = nil, router: Router) -> Route {
        return self.route(method: .any, path: path, router: router)
    }

    public static func any(_ path: String? = nil, subRoutes: [Route]) -> Route {
        return self.route(method: .any, path: path, subRoutes: subRoutes)
    }

    public static func anyWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return self.routeWithParam(method: .any, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func anyWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return self.routeWithParam(method: .any, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func anyWithParam<Param>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        return self.routeWithParam(method: .any, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Get

    public static func get(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return self.route(method: .get, path: path, handler: handler)
    }

    public static func get(_ path: String? = nil, router: Router) -> Route {
        return self.route(method: .get, path: path, router: router)
    }

    public static func get(_ path: String? = nil, subRoutes: [Route]) -> Route {
        return self.route(method: .get, path: path, subRoutes: subRoutes)
    }

    public static func getWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return self.routeWithParam(method: .get, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func getWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return self.routeWithParam(method: .get, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func getWithParam<Param>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        return self.routeWithParam(method: .get, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Post

    public static func post(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return self.route(method: .post, path: path, handler: handler)
    }

    public static func post(_ path: String? = nil, router: Router) -> Route {
        return self.route(method: .post, path: path, router: router)
    }

    public static func post(_ path: String? = nil, subRoutes: [Route]) -> Route {
        return self.route(method: .post, path: path, subRoutes: subRoutes)
    }

    public static func postWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return self.routeWithParam(method: .post, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func postWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return self.routeWithParam(method: .post, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func postWithParam<Param>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        return self.routeWithParam(method: .post, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Put

    public static func put(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return self.route(method: .put, path: path, handler: handler)
    }

    public static func put(_ path: String? = nil, router: Router) -> Route {
        return self.route(method: .put, path: path, router: router)
    }

    public static func put(_ path: String? = nil, subRoutes: [Route]) -> Route {
        return self.route(method: .put, path: path, subRoutes: subRoutes)
    }

    public static func putWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return self.routeWithParam(method: .put, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func putWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return self.routeWithParam(method: .put, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func putWithParam<Param>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        return self.routeWithParam(method: .put, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Delete

    public static func delete(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return self.route(method: .delete, path: path, handler: handler)
    }

    public static func delete(_ path: String? = nil, router: Router) -> Route {
        return self.route(method: .delete, path: path, router: router)
    }

    public static func delete(_ path: String? = nil, subRoutes: [Route]) -> Route {
        return self.route(method: .delete, path: path, subRoutes: subRoutes)
    }

    public static func deleteWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return self.routeWithParam(method: .delete, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func deleteWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return self.routeWithParam(method: .delete, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func deleteWithParam<Param>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        return self.routeWithParam(method: .delete, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // Mark: Options

    public static func options(_ path: String? = nil, handler: @escaping (Request) throws -> ResponseStatus) -> Route {
        return self.route(method: .options, path: path, handler: handler)
    }

    public static func options(_ path: String? = nil, router: Router) -> Route {
        return self.route(method: .options, path: path, router: router)
    }

    public static func options(_ path: String? = nil, subRoutes: [Route]) -> Route {
        return self.route(method: .options, path: path, subRoutes: subRoutes)
    }

    public static func optionsWithParam<Param: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, Param) throws -> ResponseStatus) -> Route {
        return self.routeWithParam(method: .options, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func optionsWithParam<R: ParameterizedRouter>(consumeEntireSubPath: Bool, router: R) -> Route where R.Param: CapturableType {
        return self.routeWithParam(method: .options, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func optionsWithParam<Param>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<Param>]) -> Route where Param: CapturableType {
        return self.routeWithParam(method: .options, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
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

fileprivate final class VariableRouterRoute<R: ParameterizedRouter>: Route where R.Param: CapturableType {
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
