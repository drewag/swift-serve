//
//  WebErrorRouter.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

import Swiftlier

class WebErrorRouter: WebRouter {
    override var routes: [Route] {
        return [
            .getWithParam(consumeEntireSubPath: true, handler: { (request, path: String) in
                let template = "\(self.configuration.viewRoot)Errors/404.html"
                guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                    return .unhandled
                }

                return .handled(try request.response(
                    template: template,
                    status: .notFound,
                    build: { context in
                        context["path"] = path
                    }
                ))
            }),
        ]
    }
}
