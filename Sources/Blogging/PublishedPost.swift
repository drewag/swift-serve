//
//  PublishedPost.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/24/17.
//
//

import Foundation

class PublishedPost: Post {
    let published: Date

    var modified: Date {
        return self.metaInfo.modified ?? self.published
    }

    var publishedYearString: String {
        let year = Calendar.current.component(.year, from: self.published)
        return "\(year)"
    }

    var publishedMonthString: String {
        let month = Calendar.current.component(.month, from: self.published)
        return month < 10 ? "0\(month)" : "\(month)"
    }

    var publishedDayString: String {
        let day = Calendar.current.component(.day, from: self.published)
        return day < 10 ? "0\(day)" : "\(day)"
    }

    var permanentRelativePath: String {
        return "posts/\(self.publishedYearString)/\(self.publishedMonthString)/\(self.publishedDayString)/\(self.urlTitle)"
    }

    var permanentRelativeImagePath: String {
        if self.hasGif {
            return self.permanentRelativePath + "/photo.gif"
        }
        else {
            return self.permanentRelativePath + "/photo.jpg"
        }
    }

    init(post: Post, published: Date) throws {
        self.published = published

        try super.init(directory: post.directory)
    }
}
