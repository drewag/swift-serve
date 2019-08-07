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
import Stencil

public protocol EmailSubscriber: TableStorable {
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

    static var field: Subscriber.Fields {get}
    static var templateName: String {get}
    var subject: String {get}
    var from: String {get}
    func build(with context: inout [String:Any])
}

public struct SubscribableEmailCenter: Router {
    let possibleEmails: [AnySubscribableEmail.Type]

    public init(emailTypes: [AnySubscribableEmail.Type]) {
        self.possibleEmails = emailTypes
        self.routes = [
            .get("unsubscribe", handler: self.unsubscribeRoute),
        ]
    }

    public var routes: [Route] = []

    func unsubscribeRoute(request: Request) throws -> ResponseStatus {
        return .handled(try request.response(template: "Views/UnsubscribeFromEmail.html", build: { context in
            guard let token = request.formValues()["token"]?.removingPercentEncoding else {
                context["error"] = "This unsubscribe link is a bad link. Please contact support"
                return
            }

            do {
                let emailType = try self.unsubscribe(usingToken: token, using: request.databaseConnection)
                context["message"] = "Unsubscribed from \(emailType.emailName) emails successfully"
            }
            catch let error {
                context["error"] = error.swiftlierError(while: "unsubscribing").description
            }
        }))
    }

    @discardableResult
    public func send<Subscribable: SubscribableEmail>(_ email: Subscribable, to subscriber: Subscribable.Subscriber, for request: Request) throws -> HTML {
        let token = try self.token(for: subscriber, to: email, using: request.databaseConnection)

        let html = try String(renderedFromTemplate: Subscribable.templateName) { context in
            context["base_url"] = request.baseURL.absoluteString
            context["unsubscribe_token"] = token?.addingPercentEncoding(withAllowedCharacters: .alphanumerics)
            email.build(with: &context)
        }

        guard token != nil else {
            return html
        }

        Email(
            to: subscriber.email.string,
            subject: email.subject,
            from: email.from,
            HTMLBody: html
        ).send()

        return html
    }

    public func unsubscribe(usingToken token: String, using connection: Connection) throws -> AnySubscribableEmail.Type {
        let components = token.components(separatedBy: "_")
        guard components.count == 3 else {
            throw GenericSwiftlierError("unsubscribing", because: "the token is invalid")
        }

        let tableName = components[0].offsetCharacters(by: -1)
        let fieldName = components[1].offsetCharacters(by: -1)
        let rawToken = components[2]

        guard let index = self.possibleEmails.firstIndex(where: {$0.tableName == tableName && $0.fieldName == fieldName}) else {
            throw GenericSwiftlierError("unsubscribing", because: "the token is invalid")
        }

        let email = self.possibleEmails[index]
        let field = QualifiedField(name: fieldName, table: tableName)
        let update = UpdateArbitraryQuery(tableName).filtered(field == rawToken)
            .setting([field:nil])
        guard try connection.execute(update).countAffected > 0 else {
            throw GenericSwiftlierError("unsubscribing", because: "the token is invalid")
        }
        return email
    }

    public func unsubscribe<Subscribable: SubscribableEmail>(_ subscriber: Subscribable.Subscriber, from: Subscribable.Type, using connection: Connection) throws {
        let update = UpdateTableQuery<Subscribable.Subscriber>().filtered(subscriber.justThisInstance)
            .setting([from.field:nil])
        try connection.execute(update)
    }

    public func subscribe<Subscribable: SubscribableEmail>(_ subscriber: Subscribable.Subscriber, to: Subscribable.Type, using connection: Connection) throws {
        let update = UpdateTableQuery<Subscribable.Subscriber>().filtered(subscriber.justThisInstance)
            .setting([to.field:Function.generateUUIDv4])
        try connection.execute(update)
    }
}

public struct AddEmailSubscriptionColumn: DatabaseChange {
    let addColumn: AddColumn

    public init<Email: SubscribableEmail>(for emailType: Email.Type, defaultToSubscribed: Bool) {
        let param: Parameter
        if defaultToSubscribed {
            let function: Function = .generateUUIDv4
            param = .function(function)
        }
        else {
            param = .null
        }
        self.addColumn = Email.Subscriber.addColumn(withSpec: FieldSpec(
            name: Email.fieldName,
            type: .uuid,
            allowNull: true,
            isUnique: true,
            references: nil,
            default: param
        ))
    }

    public var forwardQueries: [AnyQuery] {
        return self.addColumn.forwardQueries
    }

    public var revertQueries: [AnyQuery]? {
        return self.addColumn.revertQueries
    }
}

extension SubscribableEmail {
    public static var tableName: String {
        return self.Subscriber.tableName
    }

    public static var fieldName: String {
        return "\(self.field.stringValue)"
    }
}

private extension AnySubscribableEmail {
    static var field: QualifiedField {
        return QualifiedField(name: self.fieldName, table: self.tableName)
    }
}

private extension SubscribableEmail {
    var select: SelectQuery<Subscriber> {
        return Subscriber.select([type(of: self).field])
    }
}

private extension SubscribableEmailCenter {
    static func generateRawToken() -> String {
        return String(randomOfLength: 16)
    }

    func token<Subscribable: SubscribableEmail>(for subscriber: Subscribable.Subscriber, to email: Subscribable, using connection: Connection) throws -> String? {
        let result = try connection.execute(email.select.filtered(subscriber.justThisInstance))
        guard let first = result.rows.next() else {
            throw GenericSwiftlierError("sending email", because: "The subscriber could not be found")
        }

        guard let rawToken: String = try first.getIfExists(type(of: email).field) else {
            return nil
        }

        let tableName = Subscribable.tableName.offsetCharacters(by: 1)
        let fieldName = Subscribable.fieldName.offsetCharacters(by: 1)
        return "\(tableName)_\(fieldName)_\(rawToken)"
    }
}
