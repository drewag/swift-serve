//
//  ParameterizedRoute.swift
//  web
//
//  Created by Andrew J Wagner on 11/24/16.
//
//

public class ParameterizedRoute<Param: CapturableType> {
    let pathComponent: PathComponent

    init(pathComponent: PathComponent) {
        self.pathComponent = pathComponent
    }

    func route(request: Request, param: Param, to path: String) throws -> ResponseStatus {
        fatalError("Must Override")
    }
}

extension ParameterizedRoute {
    public static func any(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .any, handler: handler)
    }

    public static func any<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .any, router: router)
    }

    public static func get(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .get, handler: handler)
    }

    public static func get<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .get, router: router)
    }

    public static func post(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .post, handler: handler)
    }

    public static func post<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .post, router: router)
    }

    public static func put(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .put, handler: handler)
    }

    public static func put<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .put, router: router)
    }

    public static func delete(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .delete, handler: handler)
    }

    public static func delete<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .delete, router: router)
    }
}

fileprivate class FixedHandlerRoute<Param: CapturableType>: ParameterizedRoute<Param> {
    let handler: (Request, Param) throws -> ResponseStatus

    init(_ prefix: String?, method: HTTPMethod, handler: @escaping (Request, Param) throws -> ResponseStatus) {
        self.handler = handler
        if let prefix = prefix {
            super.init(pathComponent: StaticPathComponent(pattern: prefix, method: method, allowSubPaths: false))
        }
        else {
            super.init(pathComponent: AllPathComponent(method: method))
        }
    }

    public override func route(request: Request, param: Param, to path: String) throws -> ResponseStatus {
        return try self.handler(request, param)
    }
}

fileprivate class FixedRouterRoute<R: ParameterizedRouter>: ParameterizedRoute<R.Param> {
    let router: R

    init(_ prefix: String?, method: HTTPMethod, router: R) {
        self.router = router
        if let prefix = prefix {
            super.init(pathComponent: StaticPathComponent(pattern: prefix, method: method, allowSubPaths: true))
        }
        else {
            super.init(pathComponent: AllPathComponent(method: method))
        }
    }

    public override func route(request: Request, param: R.Param, to path: String) throws -> ResponseStatus {
        let subPath = self.pathComponent.consume(path: path)
        return try self.router.route(request: request, pathParameter: param, to: subPath)
    }
}
