//
//  PagesRouter.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

import Swiftlier

class PagesRouter: WebRouter {
    override func preprocess(request: Request, context: inout [String : Any]) throws {
        try self.configuration.preprocess?(request, &context)
    }

    override var routes: [Route] {
        return [
            .getWithParam(consumeEntireSubPath: true, handler: { (request, pagePath: String) in
                guard !pagePath.hasSuffix("base") else {
                    return .unhandled
                }

                let template = "\(self.configuration.viewRoot)Pages/\(pagePath).html"
                if nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file {
                    return .handled(try request.response(template: template))
                }

                let index = "\(self.configuration.viewRoot)Pages/\(pagePath)/index.html"
                if nil != FileSystem.default.workingDirectory.subPath(byAppending: index).file {
                    return .handled(try request.response(template: index))
                }

                return .unhandled
            }),
        ]
    }
}
