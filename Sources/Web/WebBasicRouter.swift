//
//  WebBasicRouter.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

import Swiftlier

class WebBasicsRouter: WebRouter {
    override var routes: [Route] {
        return [
            .get("robots.txt", handler: { request in
                let template = "\(self.configuration.viewRoot)Robots.txt"
                guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                    return .unhandled
                }
                return .handled(try request.response(template: template, contentType: "text/plain"))
            }),
            .get("sitemap.xml", handler: { request in
                let template = "\(self.configuration.viewRoot)Sitemap.xml"
                guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                    return .unhandled
                }
                return .handled(try request.response(template: template, contentType: "text/xml"))
            }),
        ]
    }
}
