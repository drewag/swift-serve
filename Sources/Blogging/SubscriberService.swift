//
//  SubscriberService.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 1/1/17.
//
//

import Foundation
import Swiftlier
import SQL
import Stencil

struct SubscriberService {
    let connection: Connection

    private let configuration: BlogConfiguration
    private var allSubscribers: [Subscriber]? = nil

    init(connection: Connection, configuration: BlogConfiguration) {
        self.configuration = configuration
        self.connection = connection
    }

    func addSubscriber(withEmail email: String) throws {
        guard try self.subscriber(withEmail: email) == nil else {
            return
        }
        var token: String
        repeat {
            token = Subscriber.generateUnsubscribeToken()
        } while try self.subscriber(withUnsubscribeToken: token) != nil

        let subscriber = Subscriber(email: email, unsubscribeToken: token)
        try self.connection.execute(try subscriber.insert())

        Email(
            to: self.configuration.notifyEmail,
            subject: "Notification: User Subscribed",
            from: self.configuration.notifyFromEmail,
            plainBody: "Their email is: '\(subscriber.email)'. Hopefully this IS a pattern!"
        ).send()
    }

    func unsubscribe(_ subscriber: Subscriber) throws {
        try self.connection.execute(Subscriber.delete().filtered(subscriber.justThisInstance))

        Email(
            to: self.configuration.notifyEmail,
            subject: "Notification: User Unsubscribed",
            from: self.configuration.notifyFromEmail,
            plainBody: "Their email is: '\(subscriber.email)'. Hopefully this is NOT a pattern!"
        ).send()
    }

    func subscriber(withUnsubscribeToken token: String) throws -> Subscriber? {
        let result = try self.connection.execute(Subscriber.select(forUnsubscribeToken: token))
        return try result.rows.next()?.decode(purpose: .create)
    }

    func subscriber(withEmail email: String) throws -> Subscriber? {
        let result = try self.connection.execute(Subscriber.select(forEmail: email))
        return try result.rows.next()?.decode(purpose: .create)
    }

    mutating func loadAllSubscribers() throws -> [Subscriber] {
        if let subscribers = self.allSubscribers {
            return subscribers
        }

        let results = try self.connection.execute(Subscriber.select())
        let subscribers: [Subscriber] = try results.rows.map({ try $0.decode(purpose: .create) })
        self.allSubscribers = subscribers
        return subscribers
    }

    mutating func notify(for posts: [PublishedPost], atDomain domain: String) throws {
        for subscriber in try self.loadAllSubscribers() {
            let html = try String(renderedFromTemplate: "Views/Emails/PostNotificationEmail.html") { context in
                context["domain"] = domain
                context["unsubscribeToken"] = subscriber.unsubscribeToken
                context["posts"] = posts.map { post in
                    var context = [String:Any]()
                    post.buildPublishedReference(to: &context)
                    return context
                } as [[String:Any]]
            }
            let email = Email(
                to: subscriber.email,
                subject: "New posts on drewag.me",
                from: "drewag.me notifications<donotreply@drewag.me>",
                HTMLBody: html
            )
            email.send()
        }
    }
}
