//
//  ParameterizedRoute.swift
//  web
//
//  Created by Andrew J Wagner on 11/24/16.
//
//

public class ParameterizedRoute<Param> {
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

    public static func any<R: ParameterizedRouter>(_ path: String? = nil, subRoutes: [ParameterizedRoute]) -> ParameterizedRoute<Param> where R.Param == Param {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.any(path, router: router)
    }

    public static func anyWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return VariableHandlerRoute(method: .any, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func anyWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return VariableRouterRoute(method: .any, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func anyWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.anyWithParam(consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func get(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .get, handler: handler)
    }

    public static func get<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .get, router: router)
    }

    public static func get<R: ParameterizedRouter>(_ path: String? = nil, subRoutes: [ParameterizedRoute]) -> ParameterizedRoute<Param> where R.Param == Param {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.get(path, router: router)
    }

    public static func getWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return VariableHandlerRoute(method: .get, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func getWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return VariableRouterRoute(method: .get, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func getWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.getWithParam(consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func post(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .post, handler: handler)
    }

    public static func post<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .post, router: router)
    }

    public static func post<R: ParameterizedRouter>(_ path: String? = nil, subRoutes: [ParameterizedRoute]) -> ParameterizedRoute<Param> where R.Param == Param {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.post(path, router: router)
    }

    public static func postWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return VariableHandlerRoute(method: .post, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func postWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return VariableRouterRoute(method: .post, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func postWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.postWithParam(consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func put(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .put, handler: handler)
    }

    public static func put<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .put, router: router)
    }

    public static func put<R: ParameterizedRouter>(_ path: String? = nil, subRoutes: [ParameterizedRoute]) -> ParameterizedRoute<Param> where R.Param == Param {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.put(path, router: router)
    }

    public static func putWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return VariableHandlerRoute(method: .put, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func putWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return VariableRouterRoute(method: .put, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func putWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.putWithParam(consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func delete(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: .delete, handler: handler)
    }

    public static func delete<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: .delete, router: router)
    }

    public static func delete<R: ParameterizedRouter>(_ path: String? = nil, subRoutes: [ParameterizedRoute]) -> ParameterizedRoute<Param> where R.Param == Param {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.delete(path, router: router)
    }

    public static func deleteWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return VariableHandlerRoute(method: .delete, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func deleteWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return VariableRouterRoute(method: .delete, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func deleteWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.deleteWithParam(consumeEntireSubPath: consumeEntireSubPath, router: router)
    }
}

fileprivate class FixedHandlerRoute<Param>: ParameterizedRoute<Param> {
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

fileprivate class VariableHandlerRoute<Param, NextParam: CapturableType>: ParameterizedRoute<Param> {
    let handler: (Request, (Param, NextParam)) throws -> ResponseStatus

    init(method: HTTPMethod, consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) {
        self.handler = handler
        let pathComponent = VariablePathComponent(type: NextParam.self, method: method, consumeEntireSubPath: consumeEntireSubPath)
        super.init(pathComponent: pathComponent)
    }

    fileprivate override func route(request: Request, param: Param, to path: String) throws -> ResponseStatus {
        let captureText = (self.pathComponent as! VariablePathComponent<NextParam>).captureText(fromPath: path)!
        return try self.handler(request, (param, NextParam(fromCaptureText: captureText)!))
    }
}

fileprivate class VariableRouterRoute<R: ParameterizedRouter, Param, NextParam: CapturableType>: ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
    let router: R

    init(method: HTTPMethod, consumeEntireSubPath: Bool, router: R) {
        self.router = router
        let pathComponent = VariablePathComponent(type: NextParam.self, method: method, consumeEntireSubPath: consumeEntireSubPath)
        super.init(pathComponent: pathComponent)
    }

    fileprivate override func route(request: Request, param: Param, to path: String) throws -> ResponseStatus {
        let captureText = (self.pathComponent as! VariablePathComponent<NextParam>).captureText(fromPath: path)!
        let subPath = self.pathComponent.consume(path: path)
        return try self.router.route(request: request, pathParameter: (param, NextParam(fromCaptureText: captureText)!), to: subPath)
    }
}
