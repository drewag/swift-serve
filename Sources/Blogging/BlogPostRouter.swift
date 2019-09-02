//
//  PostRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/25/16.
//
//

import Foundation
import Swiftlier

class BlogPostRouter: ParameterizedBlogRouter<(((Int, Int), Int), String)> {
    let baseLocalPath: DirectoryPath = try! FileSystem.default.workingDirectory.subdirectory("Generated").subdirectory("blog").subdirectory("posts")

    public override var routes: [ParameterizedRoute<Param>] { return [
        .get("", handler: { request, param in
            let month = param.0.0.1 < 10 ? "0\(param.0.0.1)" : "\(param.0.0.1)"
            let day = param.0.1 < 10 ? "0\(param.0.1)" : "\(param.0.1)"
            let relativePath = "\(param.0.0.0)/\(month)/\(day)/\(param.1)"
            guard let localPath = self.baseLocalPath.subPath(byAppending: relativePath).directory
                , let post = (try? Post(directory: localPath)) ?? nil
                , let publishedDate = post.metaInfo.published
                , let content = try localPath.file("content.html").file?.rendered(build: { context in
                    self.sharedBuild(context: &context)
                    context["postEndpoint"] = request.endpoint
                })
                else
            {
                return .unhandled
            }
            return .handled(try request.response(
                template: "Views/Blog/Post.html",
                build: { context in
                    context["title"] = post.metaInfo.title
                    context["summary"] = post.metaInfo.summary
                    context["metaDescription"] = post.metaInfo.metaDescription ?? post.metaInfo.summary
                    context["author"] = post.metaInfo.author
                    context["content"] = content
                    context["tags"] = post.metaInfo.tags
                    context["published"] = publishedDate.date
                    if post.hasGif {
                        context["imageUrl"] = request.endpoint.appendingPathComponent("photo.gif").relativePath
                    }
                    else if post.hasImage {
                        context["imageUrl"] = request.endpoint.appendingPathComponent("photo.jpg").relativePath
                    }
                    context["permaLink"] = request.endpoint.relativePath
                }
            ))
        }),
        .get("photo.jpg", handler: { request, param in
            let month = param.0.0.1 < 10 ? "0\(param.0.0.1)" : "\(param.0.0.1)"
            let day = param.0.1 < 10 ? "0\(param.0.1)" : "\(param.0.1)"
            let relativePath = "\(param.0.0.0)/\(month)/\(day)/\(param.1)"
            return try self.imageResponse(to: request, forPostAtRelativePath: relativePath)
        }),
        .getWithParam(consumeEntireSubPath: false, handler: { (request, params: (param: Param, imageName: String)) in
            let param = params.param

            let month = param.0.0.1 < 10 ? "0\(param.0.0.1)" : "\(param.0.0.1)"
            let day = param.0.1 < 10 ? "0\(param.0.1)" : "\(param.0.1)"
            let relativePath = "\(param.0.0.0)/\(month)/\(day)/\(param.1)"
            return try self.customImageResponse(to: request, forPostAtRelativePath: relativePath, withImageNamed: params.imageName)
        }),
    ]}
}

private extension BlogPostRouter {
    func imageResponse(to request: Request, forPostAtRelativePath relativePath: String) throws -> ResponseStatus {
        guard let localPath = self.baseLocalPath.subPath(byAppending: relativePath).directory else {
            return .unhandled
        }
        guard let post = try? Post(directory: localPath) else {
            return .unhandled
        }
        return .handled(try request.response(withFileAt: try post.imagePath().url.relativePath, status: .ok))
    }

    func customImageResponse(to request: Request, forPostAtRelativePath relativePath: String, withImageNamed imageName: String) throws -> ResponseStatus {
        guard let localPath = self.baseLocalPath.subPath(byAppending: relativePath).directory else {
            return .unhandled
        }
        guard let post = try? Post(directory: localPath) else {
            return .unhandled
        }
        guard let directory = try post.imagePath().withoutLastComponent.directory else {
            return .unhandled
        }
        let path = try directory.file(imageName)
        return .handled(try request.response(withFileAt: path.url.relativePath, status: .ok))
    }
}
