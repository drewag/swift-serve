//
//  DayRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/26/16.
//
//

class DayRouter: ParameterizedBlogRouter<((Int, Int), Int)> {
    override var routes: [ParameterizedRoute<Param>] {
        return [
            .get("", handler: { (request, date: (_: (year: Int, month: Int), day: Int)) in
                let day = date.day < 10 ? "0\(date.day)" : "\(date.day)"
                let month = date.0.month < 10 ? "0\(date.0.month)" : "\(date.0.month)"
                guard let content = try? String(contentsOfFile: "Generated/blog/posts/\(date.0.year)/\(month)/\(day)/Archive.html") else {
                    return .unhandled
                }
                return .handled(try request.response(
                    template: "Views/Blog/Navigation.html",
                    build: { context in
                        context["title"] = "Posts in \(month)/\(day)/\(date.0.year)"
                        context["content"] = content
                    }
                ))
            }),
            .getWithParam(consumeEntireSubPath: false, router: BlogPostRouter(configuration: self.configuration)),
        ]
    }
}
