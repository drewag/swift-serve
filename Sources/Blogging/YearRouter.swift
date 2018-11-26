//
//  YearRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/26/16.
//
//

class YearRouter: ParameterizedBlogRouter<Int> {
    override var routes: [ParameterizedRoute<Param>] {
        return [
            .get("", handler: { request, year in
                guard let content = try? String(contentsOfFile: "Generated/blog/posts/\(year)/Archive.html") else {
                    return .unhandled
                }
                return .handled(try request.response(
                    template: "Views/Blog/Navigation.html",
                    build: { context in
                        context["title"] = "Posts in \(year)"
                        context["content"] = content
                    }
                ))
            }),
            .getWithParam(consumeEntireSubPath: false, router: MonthRouter(configuration: self.configuration)),
        ]
    }
}
