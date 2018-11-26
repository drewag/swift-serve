//
//  PublishCommand.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/24/17.
//
//

import CommandLineParser

public struct PublishCommand {
    public static func handler(parser: Parser) throws {
        try parser.parse()

        var postsService = PostsService()
        let unpublished = try postsService.loadAllUnpublishedPosts()

        guard !unpublished.isEmpty else {
            print("All posts have been published")
            return
        }

        for post in unpublished {
            guard post.metaInfo.notified == nil else {
                continue
            }

            print("Publish \(post.metaInfo.title) (y/N)?", terminator: "")
            switch readLine(strippingNewline: true) ?? "" {
            case "y":
                try post.markPublished()
            default:
                break
            }
        }
    }
}
