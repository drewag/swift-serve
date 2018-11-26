//
//  WebStaticPagesGenerator.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/26/18.
//

import Foundation
import Swiftlier
import Stencil

class WebStaticPagesGenerator: StaticPagesGenerator {
    fileprivate let environment = Environment(loader: FileSystemLoader(paths: ["."]))

    var postsService = PostsService()

    var defaultContext: [String:Any] {
        return [:]
    }

    override func generate(forDomain domain: String) throws {
        try super.generate(forDomain: domain)

        try self.generateSiteDownPage()
        try self.generatePagesSitemap(forDomain: domain)
    }
}

private extension WebStaticPagesGenerator {
    func generateSiteDownPage() throws {
        print("Generating site down page...", terminator: "")
        var context = self.defaultContext
        context["css"] = (try? String(contentsOfFile: "Assets/css/main.css")) ?? nil
        let html = try self.environment.renderTemplate(name: "Views/Web/Template/SiteDown.html", context: context)
        try self.write(html, to: "Generated-working/site-down.html")
        print("done")
    }

    func generatePagesSitemap(forDomain domain: String) throws {
        print("Generating pages sitemap...", terminator: "")
        func locations(from directory: DirectoryPath, path: String) throws -> [String] {
            var output = [String]()
            for existing in try directory.contents() {
                guard !existing.name.hasPrefix(".") else {
                    continue
                }
                if let file = existing.file {
                    output.append(path + "/" + file.basename)
                }
                else if let directory = existing.directory {
                    output += try locations(from: directory, path: path + "/" + directory.name)
                }
            }
            return output
        }

        var context = self.defaultContext
        context["domain"] = domain
        context["locations"] = try locations(
            from: try FileSystem.default.workingDirectory.subdirectory("Views").subdirectory("Pages"),
            path: ""
        )
        let html = try self.environment.renderTemplate(name: "Views/Web/Template/SitemapUrls.xml", context: context)
        try self.write(html, to: "Generated-working/web/SitemapUrls.xml")
        print("done")
    }
}
