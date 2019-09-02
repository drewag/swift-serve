//
//  File.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/25/16.
//
//

import Foundation
import Swiftlier
import Stencil

class BlogStaticPagesGenerator: StaticPagesGenerator {
    fileprivate let environment = Environment.html

    let configuration: BlogConfiguration

    init(configuration: BlogConfiguration) {
        self.configuration = configuration
    }

    var postsService = PostsService()

    var defaultContext: [String:Any] {
        return [
            "rootBlogEndpoint": self.configuration.rootEndpoint,
        ]
    }

    override func generate(forDomain domain: String) throws {
        try super.generate(forDomain: domain)

        try self.generateIndex()
        try self.generatePosts()
        try self.generateArchive()
        try self.generateTagDirectories()
        try self.generateSitemap(forDomain: domain)
        try self.generateAtomFeed(forDomain: domain)
    }
}

private extension BlogStaticPagesGenerator {
    func generateIndex() throws {
        print("Generating index...", terminator: "")
        let (featured, recent) = try self.postsService.loadMainPosts()

        var context = self.defaultContext
        func buildPost(post: PublishedPost) -> [String:Any] {
            var context = self.defaultContext
            post.buildPublishedReference(to: &context)
            return context
        }

        context["featured"] = featured.map(buildPost)
        context["recent"] = recent.map(buildPost)

        let featuredHtml = try self.environment.renderTemplate(name: "Views/Blog/Template/FeaturedPosts.html", context: context)
        try self.write(featuredHtml, to: "Generated-working/blog/FeaturedPosts.html")
        let recentHtml = try self.environment.renderTemplate(name: "Views/Blog/Template/RecentPosts.html", context: context)
        try self.write(recentHtml, to: "Generated-working/blog/RecentPosts.html")
        print("done")
    }

    func generatePosts() throws {
        for post in try self.postsService.loadAllPublishedPosts() {
            try self.generate(post: post)
        }
    }

    func generate(post: PublishedPost) throws {
        print("Generating \(post.metaInfo.title)...", terminator: "")

        let relativePath = post.permanentRelativePath

        let html = try post.loadHtml()
        let directory = try FileSystem.default.workingDirectory
            .subdirectory("Generated-working")
            .subdirectory("blog")
            .subdirectory(relativePath)
        let htmlPath = try directory.file("content.html")
        let _ = try htmlPath.createFile(containing: html.data(using: .utf8), canOverwrite: true)

        let imagePath = try directory.file("photo.jpg")
        let _ = try post.imagePath().file?.copy(to: imagePath, canOverwrite: true)

        let gifPath = try directory.file("photo.gif")
        let _ = try post.gifPath().file?.copy(to: gifPath, canOverwrite: true)

        let metaPath = try directory.file("meta.json")
        let _ = try post.metaPath().file?.copy(to: metaPath, canOverwrite: true)

        for path in post.extraAssets {
            let destination = try directory.file(path.basename)
            let _ = try path.copy(to: destination, canOverwrite: true)
        }

        print("done")
    }

    func generateArchive() throws {
        print("Generating archive...")

        let organized = try self.postsService.loadPostsOrganizedByDate()
        for year in organized {
            for month in year.months {
                for day in month.days {
                    try self.generateArchive(for: day)
                }
                try self.generateArchive(for: month)
            }
            try self.generateArchive(for: year)
        }
        try self.generateArchive(for: organized)

        print("done")
    }

    func generateTagDirectories() throws {
        print("Generating tag directories...")

        let directory = "Generated-working/blog/posts/tags"
        self.createDirectory(at: directory)

        let organized = try self.postsService.loadPostsOrganizedByTag()
        for (tag, posts) in organized {
            try self.generateDirectory(for: tag, with: posts)
        }

        print("done")
    }

    func generateDirectory(for tag: Tag, with posts: [PublishedPost]) throws {
        print("Generating directory for \(tag.raw)...", terminator: "")

        var context = self.defaultContext
        func buildPost(post: PublishedPost) -> [String:Any] {
            var context = self.defaultContext
            post.buildPublishedReference(to: &context)
            return context
        }

        context["tag"] = tag
        context["posts"] = posts.map(buildPost)

        let html = try self.environment.renderTemplate(name: "Views/Blog/Template/TagPosts.html", context: context)
        try self.write(html, to: "Generated-working/blog/posts/tags/\(tag.link).html")

        print("done")
    }

    func generateSitemap(forDomain domain: String) throws {
        print("Generating sitemap...", terminator: "")

        let posts = try self.postsService.loadAllPublishedPosts()
        let organized = try self.postsService.loadPostsOrganizedByTag()

        guard !posts.isEmpty || !organized.isEmpty else {
            try self.write("", to: "Generated-working/blog/SitemapUrls.xml")
            print("done")
            return
        }

        var context = self.defaultContext
        context["domain"] = domain
        context["posts"] = posts.map {
            return [
                "link": $0.permanentRelativePath,
                "modified": ($0.metaInfo.modified ?? $0.metaInfo.published)?.railsDate,
            ]
        }
        context["tags"] = organized.map({ tag, _ in
            var modified = Date.distantPast
            for post in organized[tag]! {
                if post.modified > modified {
                    modified = post.modified
                }
            }
            return [
                "link": "posts/tags/\(tag.link)",
                "modified": modified.railsDate,
            ]
        }) as [[String:String]]

        let xml = try self.environment.renderTemplate(name: "Views/Blog/Template/SitemapUrls.xml", context: context)
        try self.write(xml, to: "Generated-working/blog/SitemapUrls.xml")

        print("done")
    }

    func generateAtomFeed(forDomain domain: String) throws {
        print("Generating atom feed...", terminator: "")

        let posts = try self.postsService.loadAllPublishedPosts()
        var context = self.defaultContext

        context["domain"] = domain
        context["mostRecentUpdated"] = posts.first?.modified.iso8601DateTime
        context["posts"] = posts.map({ post in
            return [
                "title": post.metaInfo.title,
                "permaLink": post.permanentRelativePath,
                "modified": post.modified.iso8601DateTime,
                "published": post.published.iso8601DateTime,
                "description": post.metaInfo.summary,
                "publishedYear": post.published.year,
                "summary": post.metaInfo.summary,
                "author": post.metaInfo.author,
                "tags": post.metaInfo.tags,
            ]
        })

        let xml = try self.environment.renderTemplate(name: "Views/Blog/Template/feed.xml", context: context)
        try self.write(xml, to: "Generated-working/blog/feed.xml")

        print("done")
    }

    func generateArchive(for day: DayPosts) throws {
        print("Generating achive for \(day.year)/\(day.month)/\(day.day)...", terminator: "")

        var context = self.defaultContext
        context["day"] = day
        let html = try self.environment.renderTemplate(name: "Views/Blog/Template/DayPosts.html", context: context)
        try self.write(html, to: "Generated-working/blog/posts/\(day.year)/\(day.month)/\(day.day)/Archive.html")

        print("done")
    }

    func generateArchive(for month: MonthPosts) throws {
        print("Generating achive for \(month.year)/\(month.month)...", terminator: "")

        var context = self.defaultContext
        context["month"] = month
        let html = try self.environment.renderTemplate(name: "Views/Blog/Template/MonthPosts.html", context: context)
        try self.write(html, to: "Generated-working/blog/posts/\(month.year)/\(month.month)/Archive.html")

        print("done")
    }

    func generateArchive(for year: YearPosts) throws {
        print("Generating achive for \(year.year)...", terminator: "")

        var context = self.defaultContext
        context["year"] = year
        let html = try self.environment.renderTemplate(name: "Views/Blog/Template/YearPosts.html", context: context)
        try self.write(html, to: "Generated-working/blog/posts/\(year.year)/Archive.html")

        print("done")
    }

    func generateArchive(for years: [YearPosts]) throws {
        print("Generating achive for all...", terminator: "")

        var context = self.defaultContext
        context["years"] = years
        let html = try self.environment.renderTemplate(name: "Views/Blog/Template/AllPosts.html", context: context)
        try self.write(html, to: "Generated-working/blog/posts/Archive.html")

        print("done")
    }
}
