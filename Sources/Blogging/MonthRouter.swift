//
//  MonthRouter.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/26/16.
//
//

class MonthRouter: ParameterizedBlogRouter<(Int, Int)> {
    override var routes: [ParameterizedRoute<Param>] {
        return [
            .get("", handler: { (request, date: (year: Int, month: Int)) in
                let month = date.month < 10 ? "0\(date.month)" : "\(date.month)"
                guard let content = try? String(contentsOfFile: "Generated/blog/posts/\(date.year)/\(month)/Archive.html") else {
                    return .unhandled
                }
                return .handled(try request.response(
                    template: "Views/Blog/Navigation.html",
                    build: { context in
                        context["title"] = "Posts on \(month)/\(date.year)"
                        context["content"] = content
                    }
                ))
            }),
            .getWithParam(consumeEntireSubPath: false, router: DayRouter(configuration: self.configuration)),
        ]
    }
}
