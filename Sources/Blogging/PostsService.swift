//
//  PostService.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 12/23/16.
//
//

import Foundation
import Swiftlier

final class DayPosts {
    let year: String
    let month: String
    let day: String
    let displayDay: String
    private(set) var posts: [PublishedPost]

    init(post: PublishedPost) {
        self.day = post.publishedDayString
        self.month = post.publishedMonthString
        self.year = post.publishedYearString
        self.displayDay = post.metaInfo.publishedDescription
        self.posts = [post]
    }

    func append(post: PublishedPost) {
        self.posts.append(post)
    }
}

final class  MonthPosts {
    let year: String
    let month: String
    let displayMonth: String
    private(set) var days: [DayPosts]

    init(post: PublishedPost) {
        self.month = post.publishedMonthString
        self.displayMonth = post.published.month
        self.year = post.publishedYearString
        self.days = [DayPosts(post: post)]
    }

    func append(post: PublishedPost) {
        let day = post.publishedDayString
        if let index = self.days.firstIndex(where: {$0.day == day}) {
            self.days[index].append(post: post)
        }
        else {
            self.days.append(DayPosts(post: post))
        }
    }
}

final class YearPosts {
    let year: String
    private(set) var months: [MonthPosts]

    init(post: PublishedPost) {
        self.year = post.publishedYearString
        self.months = [MonthPosts(post: post)]
    }

    func append(post: PublishedPost) {
        let month = post.publishedMonthString
        if let index = self.months.firstIndex(where: {$0.month == month}) {
            self.months[index].append(post: post)
        }
        else {
            self.months.append(MonthPosts(post: post))
        }
    }
}

struct PostsService {
    private var allPosts: [Post]?

    mutating func loadAllPosts() throws -> [Post] {
        if let posts = self.allPosts {
            return posts
        }

        let directory = try FileSystem.default.workingDirectory.subdirectory("Posts")
        let posts = try directory.contents()
            .compactMap({$0.directory})
            .filter({$0.name != ".git"})
            .map({try Post(directory: $0)})
            .sorted(by: {($0.metaInfo.published ?? Date.distantFuture).timeIntervalSince($1.metaInfo.published ?? Date.distantFuture) > 0})
        self.allPosts = posts
        return posts
    }

    mutating func loadAllPublishedPosts() throws -> [PublishedPost] {
        return try self.loadAllPosts()
            .filter({$0.metaInfo.published != nil})
            .map({try PublishedPost(post: $0, published: $0.metaInfo.published!)})
    }

    mutating func loadAllUnpublishedPosts() throws -> [Post] {
        return try self.loadAllPosts().filter({$0.metaInfo.published == nil})
    }

    mutating func loadAllUnnotifiedPosts() throws -> [PublishedPost] {
        return try self.loadAllPublishedPosts()
            .filter({$0.metaInfo.notified == nil})
    }

    mutating func loadPostsOrganizedByDate() throws -> [YearPosts] {
        var years = [YearPosts]()

        var mostRecentYear: YearPosts?

        // Published posts are already sorted by date
        for post in try self.loadAllPublishedPosts() {
            let year = post.publishedYearString
            if let recent = mostRecentYear, recent.year == year {
                recent.append(post: post)
            }
            else {
                let recent = YearPosts(post: post)
                mostRecentYear = recent
                years.append(recent)
            }
        }

        return years
    }

    mutating func loadPostsOrganizedByTag() throws -> [Tag:[PublishedPost]] {
        var organized = [Tag:[PublishedPost]]()

        for post in try self.loadAllPublishedPosts() {
            for tag in post.metaInfo.tags {
                var postArray = organized[tag] ?? []
                postArray.append(post)
                organized[tag] = postArray
            }
        }

        return organized
    }

    mutating func loadMainPosts() throws -> (featured: [PublishedPost], recent: [PublishedPost]) {
        var featured = [PublishedPost]()
        var recent = [PublishedPost]()

        for post in try self.loadAllPublishedPosts() {
            if post.metaInfo.isFeatured {
                featured.append(post)
            }
            else if recent.count < 10 {
                recent.append(post)
            }
        }

        return (featured: featured, recent: recent)
    }
}
