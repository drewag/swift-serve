//
//  WebBasicRouter.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

import Swiftlier

struct WebBasicsRouter: Router {
    let routes: [Route] = [
        .get("robots.txt", handler: { request in
            let template = "Views/Robots.txt"
            guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                return .unhandled
            }
            return .handled(try request.response(template: template, contentType: "text/plain"))
        }),
        .get("sitemap.xml", handler: { request in
            let template = "Views/Sitemap.xml"
            guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                return .unhandled
            }
            return .handled(try request.response(template: template, contentType: "text/xml"))
        }),
    ]
}
