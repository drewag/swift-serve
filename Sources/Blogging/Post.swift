//
//  Post.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/23/16.
//
//

import Foundation
import Swiftlier
import PerfectMarkdown
import Stencil

struct Tag: Hashable {
    let raw: String
    let display: String
    let link: String

    init(string: String) {
        self.raw = string
        self.display = string.lowercased()
        self.link = string.lowercased().replacingOccurrences(of: " ", with: "-")
    }

    func hash(into hasher: inout Hasher) {
        self.display.hash(into: &hasher)
    }
}

class Post: DynamicStringReferencable {
    let directory: DirectoryPath

    struct MetaInfo {
        let title: String
        let author: String
        let summary: String
        let metaDescription: String?
        let isFeatured: Bool
        let imageHeight: Int?
        let tags: [Tag]

        var publishedDescription: String
        var published: Date? {
            didSet {
                self.refresh()
            }
        }
        var notified: Date?
        var modified: Date?

        init(
            title: String,
            author: String,
            summary: String,
            metaDescription: String?,
            isFeatured: Bool,
            imageHeight: Int?,
            tags: [Tag],
            published: Date?,
            notified: Date?,
            modified: Date?
            )
        {
            self.title = title
            self.author = author
            self.summary = summary
            self.metaDescription = metaDescription
            self.isFeatured = isFeatured
            self.imageHeight = imageHeight
            self.tags = tags
            self.published = published
            self.notified = notified
            self.modified = modified
            self.publishedDescription = ""

            self.refresh()
        }

        private mutating func refresh() {
            guard let timestamp = self.published else {
                self.publishedDescription = "Unpublished"
                return
            }
            self.publishedDescription = timestamp.date
        }
    }

    let urlTitle: String

    private(set) var metaInfo: MetaInfo
    private(set) var extraAssets: [FilePath]
    fileprivate var html: String?
    var hasImage: Bool {
        guard let path = try? self.imagePath() else {
            return false
        }
        return nil != path.file
    }

    var hasGif: Bool {
        guard let path = try? self.gifPath() else {
            return false
        }
        return nil != path.file
    }

    func loadHtml() throws -> String {
        if let html = self.html {
            return html
        }

        let text = try self.contentsPath().file?.string() ?? ""
        var html = (text.markdownToHTML ?? "")
        if let regex = try? NSRegularExpression(pattern: "<pre><code>// (.*)$\\n", options: [.caseInsensitive,.anchorsMatchLines]) {
            let range = NSMakeRange(0, html.count)
            html = regex.stringByReplacingMatches(in: html, options: [], range: range, withTemplate: "<pre><code class=\"lang-$1\">")
        }
        return html
    }

    func imagePath() throws -> Path {
        return try self.directory.file("photo.jpg")
    }

    func gifPath() throws -> Path {
        return try self.directory.file("photo.gif")
    }

    static func metaPath(in directory: DirectoryPath) throws -> Path {
        return try directory.file("meta.json")
    }

    func metaPath() throws -> Path {
        return try type(of: self).metaPath(in: self.directory)
    }

    func markPublished() throws {
        self.metaInfo.published = Date()
        try self.saveMeta()
    }

    func markNotified() throws {
        self.metaInfo.notified = Date()
        try self.saveMeta()
    }

    init(directory: DirectoryPath) throws {
        self.directory = directory

        guard let file = try Post.metaPath(in: directory).file else {
            throw GenericSwiftlierError("loading post", because: "the meta file doesn't exist")
        }

        let metaInfo = try JSONDecoder().decode(MetaInfo.self, from: try file.contents())
        self.metaInfo = metaInfo
        let allAssets = try self.directory.contents().compactMap({$0.file})
        self.extraAssets = allAssets
            .filter({$0.extension == "gif" || $0.extension == "jpg" || $0.extension == "png"})
            .filter({$0.basename != "photo.jpg"})

        let components = directory.name.components(separatedBy: "-")
        self.urlTitle = components[1 ..< components.count].joined(separator: "-")
    }

    subscript(_ key: String) -> Any? {
        switch key {
        case "title":
            return self.metaInfo.title
        case "description":
            return self.metaInfo.summary
        case "summary":
            return self.metaInfo.summary
        case "author":
            return self.metaInfo.author
        case "tags":
            return self.metaInfo.tags
        default:
            return nil
        }
    }
}


fileprivate extension Post {
    func contentsPath() throws -> Path {
        return try self.directory.file("content.md")
    }
}

private extension Post {
    func saveMeta() throws {
        let path = try Post.metaPath(in: self.directory)
        try path.createFile(containingEncodable: self.metaInfo, canOverwrite: true)
    }
}

extension Tag: Codable {
    init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self.init(string: string)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.raw)
    }
}

extension Post.MetaInfo: Codable {
    enum CodingKeys: String, CodingKey {
        case title, summary, author, isFeatured = "featured"
        case imageHeight = "image_height", tags, published
        case notified, modified
        case metaDescription
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decode(String.self, forKey: .title),
            author: try container.decode(String.self, forKey: .author),
            summary: try container.decode(String.self, forKey: .summary),
            metaDescription: try container.decodeIfPresent(String.self, forKey: .metaDescription),
            isFeatured: try container.decode(Bool.self, forKey: .isFeatured),
            imageHeight: try container.decodeIfPresent(Int.self, forKey: .imageHeight),
            tags: try container.decode([Tag].self, forKey: .tags),
            published: try container.decodeIfPresent(String.self, forKey: .published)?.iso8601DateTime,
            notified: try container.decodeIfPresent(String.self, forKey: .notified)?.iso8601DateTime,
            modified: try container.decodeIfPresent(String.self, forKey: .modified)?.iso8601DateTime
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.summary, forKey: .summary)
        try container.encode(self.published?.iso8601DateTime, forKey: .published)
        try container.encode(self.isFeatured, forKey: .isFeatured)
        try container.encode(self.tags, forKey: .tags)
        try container.encode(self.author, forKey: .author)
        try container.encode(self.metaDescription, forKey: .metaDescription)
        if let notified = self.notified {
            try container.encode(notified.iso8601DateTime, forKey: .notified)
        }
        if let modified = self.modified {
            try container.encode(modified.iso8601DateTime, forKey: .modified)
        }
    }
}
