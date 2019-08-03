//
//  ParameterizedRoute.swift
//  web
//
//  Created by Andrew J Wagner on 11/24/16.
//
//

import Swiftlier
import Decree

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
    // MARK: Generic

    public static func route(method: Method?, path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return FixedHandlerRoute(path, method: method, handler: handler)
    }

    public static func route<R: ParameterizedRouter>(method: Method?, path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return FixedRouterRoute(path, method: method, router: router)
    }

    public static func route(method: Method?, path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.route(method: method, path: path, router: router)
    }

    public static func routeWithParam<NextParam: CapturableType>(method: Method?, consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return VariableHandlerRoute(method: method, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func routeWithParam<R: ParameterizedRouter, NextParam: CapturableType>(method: Method?, consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return VariableRouterRoute(method: method, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func routeWithParam<NextParam: CapturableType>(method: Method?, consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        let router = InPlaceParameterizedRouter(routes: subRoutes)
        return self.routeWithParam(method: method, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    // MARK: Any

    public static func any(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return self.route(method: nil, path: path, handler: handler)
    }

    public static func any<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return self.route(method: nil, path: path, router: router)
    }

    public static func any(_ path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        return self.route(method: nil, path: path, subRoutes: subRoutes)
    }

    public static func anyWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return routeWithParam(method: nil, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func anyWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return routeWithParam(method: nil, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func anyWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        return routeWithParam(method: nil, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Get

    public static func get(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return self.route(method: .get, path: path, handler: handler)
    }

    public static func get<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return self.route(method: .get, path: path, router: router)
    }

    public static func get(_ path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        return self.route(method: .get, path: path, subRoutes: subRoutes)
    }

    public static func getWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .get, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func getWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return routeWithParam(method: .get, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func getWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .get, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Post

    public static func post(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return self.route(method: .post, path: path, handler: handler)
    }

    public static func post<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return self.route(method: .post, path: path, router: router)
    }

    public static func post(_ path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        return self.route(method: .post, path: path, subRoutes: subRoutes)
    }

    public static func postWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .post, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func postWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return routeWithParam(method: .post, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func postWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .post, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Put

    public static func put(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return self.route(method: .put, path: path, handler: handler)
    }

    public static func put<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return self.route(method: .put, path: path, router: router)
    }

    public static func put(_ path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        return self.route(method: .put, path: path, subRoutes: subRoutes)
    }

    public static func putWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .put, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func putWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return routeWithParam(method: .put, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func putWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .put, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Delete

    public static func delete(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return self.route(method: .delete, path: path, handler: handler)
    }

    public static func delete<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return self.route(method: .delete, path: path, router: router)
    }

    public static func delete(_ path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        return self.route(method: .delete, path: path, subRoutes: subRoutes)
    }

    public static func deleteWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .delete, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func deleteWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return routeWithParam(method: .delete, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func deleteWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .delete, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }

    // MARK: Options

    public static func options(_ path: String? = nil, handler: @escaping (Request, Param) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return self.route(method: .options, path: path, handler: handler)
    }

    public static func options<R: ParameterizedRouter>(_ path: String? = nil, router: R) -> ParameterizedRoute<Param> where R.Param == Param {
        return self.route(method: .options, path: path, router: router)
    }

    public static func options(_ path: String? = nil, subRoutes: [ParameterizedRoute<Param>]) -> ParameterizedRoute<Param> {
        return self.route(method: .options, path: path, subRoutes: subRoutes)
    }

    public static func optionsWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .options, consumeEntireSubPath: consumeEntireSubPath, handler: handler)
    }

    public static func optionsWithParam<R: ParameterizedRouter, NextParam: CapturableType>(consumeEntireSubPath: Bool, router: R) -> ParameterizedRoute<Param> where R.Param == (Param, NextParam) {
        return routeWithParam(method: .options, consumeEntireSubPath: consumeEntireSubPath, router: router)
    }

    public static func optionsWithParam<NextParam: CapturableType>(consumeEntireSubPath: Bool, subRoutes: [ParameterizedRoute<(Param, NextParam)>]) -> ParameterizedRoute<Param> {
        return routeWithParam(method: .options, consumeEntireSubPath: consumeEntireSubPath, subRoutes: subRoutes)
    }
}

fileprivate class FixedHandlerRoute<Param>: ParameterizedRoute<Param> {
    let handler: (Request, Param) throws -> ResponseStatus

    init(_ prefix: String?, method: Method?, handler: @escaping (Request, Param) throws -> ResponseStatus) {
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

    init(_ prefix: String?, method: Method?, router: R) {
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

    init(method: Method?, consumeEntireSubPath: Bool, handler: @escaping (Request, (Param, NextParam)) throws -> ResponseStatus) {
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

    init(method: Method?, consumeEntireSubPath: Bool, router: R) {
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
