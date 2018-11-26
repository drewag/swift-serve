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
            guard !pagePath.hasSuffix("base") else {
                return .unhandled
            }

            let template = "Views/Pages/\(pagePath).html"
            if nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file {
                return .handled(try request.response(template: template))
            }

            let index = "Views/Pages/\(pagePath)/index.html"
            if nil != FileSystem.default.workingDirectory.subPath(byAppending: index).file {
                return .handled(try request.response(template: index))
            }

            return .unhandled
        }),
    ]
}
