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
    public static func any(_ path: String, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .any, handler: handler)
    }

    public static func any(_ path: String, router: Router) -> Route {
        return FixedRouterRoute(path, method: .any, router: router)
    }

    public static func get(_ path: String, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .get, handler: handler)
    }

    public static func get(_ path: String, router: Router) -> Route {
        return FixedRouterRoute(path, method: .get, router: router)
    }

    public static func post(_ path: String, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .post, handler: handler)
    }

    public static func post(_ path: String, router: Router) -> Route {
        return FixedRouterRoute(path, method: .post, router: router)
    }

    public static func put(_ path: String, handler: @escaping (Request) throws -> RouterResponse) -> Route {
        return FixedHandlerRoute(path, method: .put, handler: handler)
    }

    public static func put(_ path: String, router: Router) -> Route {
        return FixedRouterRoute(path, method: .put, router: router)
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
