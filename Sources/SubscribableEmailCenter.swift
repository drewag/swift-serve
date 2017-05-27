//
//  SubscribableEmailCenter.swift
//  web
//
//  Created by Andrew J Wagner on 5/21/17.
//
//

import Foundation
import Swiftlier
import SQL
import TextTransformers
import PostgreSQL

public protocol EmailSubscriber: TableProtocol {
    var email: EmailAddress {get}
    var justThisInstance: Predicate {get}
}

public protocol AnySubscribableEmail {
    static var tableName: String {get}
    static var fieldName: String {get}
    static var emailName: String {get}
}

public protocol SubscribableEmail: AnySubscribableEmail {
    associatedtype Subscriber: EmailSubscriber

    static var field: Subscriber.Field {get}
    static var templatePath: Path {get}
    var subject: String {get}
    var from: String {get}
    func build(with builder: TemplateBuilder)
}

public struct SubscribableEmailCenter: ErrorGenerating, Router {
    struct ErrorReason {
        static let invalidToken = Swiftlier.ErrorReason("the token is invalid")
    }

    let possibleEmails: [AnySubscribableEmail.Type]

    public init(emailTypes: [AnySubscribableEmail.Type]) {
        self.possibleEmails = emailTypes
        self.routes = [
            .get("unsubscribe", handler: self.unsubscribeRoute),
        ]
    }

    public var routes: [Route] = []

    func unsubscribeRoute(request: Request) throws -> ResponseStatus {
        return .handled(try request.response(htmlFromFile: "Views/UnsubscribeFromEmail.html", htmlBuild: { builder in
            guard let token = request.formValues()["token"]?.removingPercentEncoding else {
                builder["error"] = "This unsubscribe link is a bad link. Please contact support"
                return
            }

            do {
                let emailType = try self.unsubscribe(usingToken: token, using: request.databaseConnection)
                builder["message"] = "Unsubscribed from \(emailType.emailName) emails successfully"
            }
            catch let error {
                builder["error"] = request.error("unsubscribing", from: error).description
            }
        }))
    }

    @discardableResult
    public func send<Subscribable: SubscribableEmail>(_ email: Subscribable, to subscriber: Subscribable.Subscriber, for request: Request) throws -> HTML? {
        guard let token = try self.token(for: subscriber, to: email, using: request.databaseConnection) else {
            return nil
        }

        let html = try type(of: email).templatePath.url.relativePath
            .map(FileContents())
            .map(Template(build: { builder in
                builder["base_url"] = request.baseURL.absoluteString
                builder["unsubscribe_token"] = token.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
                email.build(with: builder)
            }))
            .string()
        Email(
            to: subscriber.email.string,
            subject: email.subject,
            from: email.from,
            HTMLBody: html
        ).send()

        return html
    }

    public func unsubscribe(usingToken token: String, using connection: DatabaseConnection) throws -> AnySubscribableEmail.Type {
        let components = token.components(separatedBy: "_")
        guard components.count == 3 else {
            throw self.userError("unsubscribing", because: ErrorReason.invalidToken)
        }

        let tableName = components[0].offsetCharacters(by: -1)
        let fieldName = components[1].offsetCharacters(by: -1)
        let rawToken = components[2]

        guard let index = self.possibleEmails.index(where: {$0.tableName == tableName && $0.fieldName == fieldName}) else {
            throw self.userError("unsubscribing", because: ErrorReason.invalidToken)
        }

        let email = self.possibleEmails[index]
        let field = QualifiedField("\(tableName).\(fieldName)")
        var update = Update(tableName).filtered(field == rawToken)
        update.set([field:nil])
        guard try connection.execute(update).countAffected > 0 else {
            throw self.userError("unsubscribing", because: ErrorReason.invalidToken)
        }
        return email
    }
}

public struct AddEmailSubscriptionColumn: DatabaseChange {
    let addColumn: AddColumn

    public init<Email: SubscribableEmail>(for emailType: Email.Type, defaultToSubscribed: Bool) {
        self.addColumn = AddColumn(to: Email.tableName, with: FieldSpec(
            name: Email.fieldName,
            type: .uuid,
            allowNull: true,
            isUnique: true,
            references: nil,
            default: defaultToSubscribed ? .calculated("uuid_generate_v4()") : nil
        ))
    }

    public var forwardQuery: String {
        return "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
            + self.addColumn.forwardQuery
    }

    public var revertQuery: String? {
        return self.addColumn.revertQuery
    }
}

extension SubscribableEmail {
    public static var tableName: String {
        return self.Subscriber.Field.tableName
    }

    public static var fieldName: String {
        return "\(self.field.rawValue)"
    }
}

private extension SubscribableEmail {
    var select: Select {
        return Select("\(type(of: self).field.rawValue)", from: type(of: self).Subscriber.Field.tableName)
    }
}

private extension SubscribableEmailCenter {
    static func generateRawToken() -> String {
        return String(randomOfLength: 16)
    }

    func token<Subscribable: SubscribableEmail>(for subscriber: Subscribable.Subscriber, to email: Subscribable, using connection: DatabaseConnection) throws -> String? {
        let result = try connection.execute(email.select.filtered(subscriber.justThisInstance))
        guard let first = result.first else {
            throw self.error("sending email", because: "The subscriber could not be found")
        }

        guard let rawToken: String = try first.value("\(type(of: email).field.rawValue)") else {
            return nil
        }

        let tableName = Subscribable.tableName.offsetCharacters(by: 1)
        let fieldName = Subscribable.fieldName.offsetCharacters(by: 1)
        return "\(tableName)_\(fieldName)_\(rawToken)"
    }
}
