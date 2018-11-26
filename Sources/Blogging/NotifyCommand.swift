//
//  NotifyCommand.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/24/17.
//
//

import CommandLineParser
import PostgreSQL

public struct NotifyCommand {
    public static func handler(configuration: BlogConfiguration) -> ((_ parser: Parser) throws -> ()) {
        return { parser in
            let domain = parser.string(named: "domain")
            try parser.parse()

            let connection = PostgreSQLConnection()
            var postsService = PostsService()

            let unnotified = try postsService.loadAllUnnotifiedPosts()

            guard !unnotified.isEmpty else {
                print("All published posts have been notified")
                return
            }

            var toNotify = [PublishedPost]()
            for post in unnotified {
                print("Send notification for \(post.metaInfo.title) (y/N)?", terminator: "")
                switch readLine(strippingNewline: true) ?? "" {
                case "y":
                    toNotify.append(post)
                default:
                    break
                }
            }

            guard toNotify.count > 0 else {
                return
            }

            var subscriberService = SubscriberService(connection: connection, configuration: configuration)
            try subscriberService.notify(for: toNotify, atDomain: domain.parsedValue)

            for post in toNotify {
                try post.markNotified()
            }
        }
    }
}
