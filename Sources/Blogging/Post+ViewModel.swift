//
//  Post+ViewModel.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/25/16.
//
//

import Foundation

extension Post {
    func buildPreviewContent(to context: inout [String:Any], atUrl baseUrl: URL, withPermaLink permaLink: String? = nil) throws {
        let permaLink = permaLink ?? ("preview/" + self.directory.name)
        context["title"] = self.metaInfo.title
        context["author"] = self.metaInfo.author
        context["published"] = self.metaInfo.published?.date ?? "Unpublished"
        context["isoPublished"] = self.metaInfo.published?.iso8601DateTime ?? "Unpublished"
        context["isoModified"] = self.metaInfo.modified?.iso8601DateTime ?? "Unpublished"
        context["summary"] = self.metaInfo.summary
        if self.hasGif {
            context["imageUrl"] = baseUrl.appendingPathComponent("photo.gif").relativePath
        }
        else if self.hasImage {
            context["imageUrl"] = baseUrl.appendingPathComponent("photo.jpg").relativePath
        }
        context["content"] = try self.loadHtml().replacingOccurrences(of: "{{postEndpoint}}", with: permaLink)
        context["tags"] = self.metaInfo.tags
    }

    func buildPreviewReference(to context: inout [String:Any]) {
        context["title"] = self.metaInfo.title
        context["author"] = self.metaInfo.author
        context["published"] = self.metaInfo.published?.date ?? "Unpublished"
        context["summary"] = self.metaInfo.summary
        if self.hasGif {
            context["imageUrl"] = "preview/" + self.directory.name + "/photo.gif"
        }
        else if self.hasImage {
            context["imageUrl"] = "preview/" + self.directory.name + "/photo.jpg"
        }
        context["link"] = "preview/" + self.directory.name
        context["tags"] = self.metaInfo.tags.map { tag in
            return [
                "name": tag.display,
                "link": "posts/tags/\(tag.link)",
            ]
        }
    }
}

extension PublishedPost {
    func buildPublishedContent(to context: inout [String:Any], atUrl baseUrl: URL) throws {
        try self.buildPreviewContent(to: &context, atUrl: baseUrl, withPermaLink: self.permanentRelativePath)
        context["permaLink"] = self.permanentRelativePath
        context["imageUrl"] = self.permanentRelativeImagePath
    }

    func buildPublishedReference(to context: inout [String:Any]) {
        self.buildPreviewReference(to: &context)

        context["imageUrl"] = self.permanentRelativeImagePath
        context["link"] = self.permanentRelativePath
    }
}
