//
//  PagesRouter.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

import Swiftlier

struct PagesRouter: Router {
    let routes: [Route] = [
        .getWithParam(consumeEntireSubPath: true, handler: { (request, pagePath: String) in
            let template = "Views/Pages/\(pagePath).html"
            guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                return .unhandled
            }
            return .handled(try request.response(template: template))
        }),
    ]
}
