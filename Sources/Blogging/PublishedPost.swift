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
        let calendar = Calendar(identifier: .gregorian)
        let units = Set<Calendar.Component>([.year])
        let components = calendar.dateComponents(units, from: self.published)
        return "\(components.year!)"
    }

    var publishedMonthString: String {
        let calendar = Calendar(identifier: .gregorian)
        let units = Set<Calendar.Component>([.month])
        let components = calendar.dateComponents(units, from: self.published)
        return components.month! < 10 ? "0\(components.month!)" : "\(components.month!)"
    }

    var publishedDayString: String {
        let calendar = Calendar(identifier: .gregorian)
        let units = Set<Calendar.Component>([.day])
        let components = calendar.dateComponents(units, from: self.published)
        return components.day! < 10 ? "0\(components.day!)" : "\(components.day!)"
    }

    var permanentRelativePath: String {
        return "posts/\(self.publishedYearString)/\(self.publishedMonthString)/\(self.publishedDayString)/\(self.urlTitle)"
    }

    var permanentRelativeImagePath: String {
        return self.permanentRelativePath + "/photo.jpg"
    }

    init(post: Post, published: Date) throws {
        self.published = published

        try super.init(directory: post.directory)
    }
}
