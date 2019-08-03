//
//  Subscriber.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/1/17.
//
//

import Foundation
import SQL
import Swiftlier

public struct Subscriber: TableStorable {
    public static let tableName = "subscribers"

    public typealias CodingKeys = Fields

    public enum Fields: String, Field, CodingKey {
        case email
        case unsubscribeToken = "unsubscribe_token"
        case subscribed = "subscribed_date"

        public var sqlFieldSpec: FieldSpec? {
            switch self {
            case .email:
                return self.spec(dataType: .string(length: 100), allowNull: false, isUnique: true)
            case .unsubscribeToken:
                return self.spec(dataType: .string(length: 16), allowNull: false, isUnique: true)
            case .subscribed:
                return self.spec(dataType: .date, allowNull: false)
            }
        }
    }

    let email: String
    let unsubscribeToken: String
    let subscribed: Date

    static func generateUnsubscribeToken() -> String {
        return self.generateRandomString(ofLength: 16)
    }

    static func select(forEmail email: String) -> SelectQuery<Subscriber> {
        return self.select().filtered(self.field(.email) == email.lowercased())
    }

    static func select(forUnsubscribeToken token: String) -> SelectQuery<Subscriber> {
        return self.select().filtered(self.field(.unsubscribeToken) == token)
    }

    init(email: String, unsubscribeToken: String, subscribed: Date) {
        self.email = email.lowercased()
        self.unsubscribeToken = unsubscribeToken
        self.subscribed = subscribed
    }

    init(email: String, unsubscribeToken: String) {
        self.init(email: email, unsubscribeToken: unsubscribeToken, subscribed: Date())
    }

    var justThisInstance: Predicate {
        return type(of: self).field(.email) == self.email
    }
}

extension Subscriber: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawSubscribed = try container.decode(String.self, forKey: .subscribed)
        guard let subscribed = rawSubscribed.railsDate else {
            throw DecodingError.dataCorruptedError(forKey: .subscribed, in: container, debugDescription: "invalid date")
        }

        self.init(
            email: try container.decode(String.self, forKey: .email),
            unsubscribeToken: try container.decode(String.self, forKey: .unsubscribeToken),
            subscribed: subscribed
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.email, forKey: .email)
        try container.encode(self.unsubscribeToken, forKey: .unsubscribeToken)
        try container.encode(self.subscribed.railsDate, forKey: .subscribed)
    }
}

private extension Subscriber {
    static func generateRandomString(ofLength length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let allowedCharsCount = UInt32(allowedChars.count)

        var output = ""
        for _ in 0 ..< length {
            #if os(Linux)
                let randomNumber = Int(random()) % Int(allowedCharsCount)
            #else
                let randomNumber = Int(arc4random_uniform(allowedCharsCount))
            #endif
            let index = allowedChars.index(allowedChars.startIndex, offsetBy: randomNumber)
            let newCharacter = allowedChars[index]
            output.append(newCharacter)
        }
        return output
    }
}
