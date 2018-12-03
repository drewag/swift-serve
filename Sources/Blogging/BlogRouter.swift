//
//  PublishedRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/26/16.
//
//

import Foundation
import Swiftlier
import CommandLineParser
import SQL

protocol AnyBlogRouter {
    var configuration: BlogConfiguration {get}
}

extension AnyBlogRouter {
    func sharedBuild(context: inout [String:Any]) {
        context["rootBlogEndpoint"] = self.configuration.rootEndpoint
    }
}

public class ConcreteBlogRouter: Router, AnyBlogRouter {
    let configuration: BlogConfiguration

    public init(configuration: BlogConfiguration) {
        self.configuration = configuration
    }

    public var routes: [Route] {
        return []
    }

    public func preprocess(request: Request, context: inout [String : Any]) throws {
        self.sharedBuild(context: &context)
    }
}

public class ParameterizedBlogRouter<Param>: ParameterizedRouter, AnyBlogRouter {
    let configuration: BlogConfiguration

    public init(configuration: BlogConfiguration) {
        self.configuration = configuration
    }

    public var routes: [ParameterizedRoute<Param>] {
        return []
    }

    public func preprocess(request: Request, context: inout [String : Any]) throws {
        self.sharedBuild(context: &context)
    }
}

class BlogRouter: ConcreteBlogRouter {
    override var routes: [Route] {
        return [
            .get("feed", handler: { request in
                let template = "Generated/blog/feed.xml"
                guard nil != FileSystem.default.workingDirectory.subPath(byAppending: template).file else {
                    return .unhandled
                }
                return .handled(try request.response(template: template, contentType: "application/atom+xml"))
            }),
            .any("subscribers", router: SubscribersRouter(configuration: self.configuration)),
            .get("", handler: { request in
                return .handled(try request.response(template: "Views/Blog/Home.html"))
            }),
            .get("posts", subRoutes: [
                .get("", handler: { request in
                    guard let content = try? String(contentsOfFile: "Generated/blog/posts/Archive.html") else {
                        return .unhandled
                    }
                    return .handled(try request.response(
                        template: "Views/Blog/Navigation.html",
                        build: { context in
                            context["title"] = "All Posts"
                            context["content"] = content
                        }
                    ))
                }),
                .get("tags", subRoutes: [
                    .getWithParam(consumeEntireSubPath: false, handler: { (request, rawTag: String) in
                        guard let content = try? String(contentsOfFile: "Generated/blog/posts/tags/\(rawTag).html") else {
                            return .unhandled
                        }
                        return .handled(try request.response(
                            template: "Views/Blog/Navigation.html",
                            build: { context in
                                context["title"] = "\(rawTag) Posts"
                                context["content"] = content
                            }
                        ))
                    }),
                ]),
                .getWithParam(consumeEntireSubPath: false, router: YearRouter(configuration: self.configuration)),
                .getWithParam(consumeEntireSubPath: false, handler: { (request, title: String) in
                    do {
                        let redirectEndpoint = try String(contentsOfFile: "OldPermalinks/\(title)")
                        if !redirectEndpoint.isEmpty {
                            return .handled(request.response(redirectingTo: "\(redirectEndpoint)", permanently: true))
                        }
                    }
                    catch {}

                    return .unhandled
                }),
            ]),
        ]
    }

    func addCommands(to parser: Parser) {
        parser.command(named: "publish", handler: PublishCommand.handler)
        parser.command(named: "notify", handler: NotifyCommand.handler(configuration: self.configuration))
    }

    func migrate(from: SwiftServeInternal, in connection: Connection) throws {
        var from = from
        if !from.subscribers {
            for query in Subscriber.create(ifNotExists: true, fields: [.email, .unsubscribeToken, .subscribed]).forwardQueries {
                try connection.executeIgnoringResult(query)
            }
            from.subscribers = true
            try connection.execute(try from.update())
        }
    }
}
