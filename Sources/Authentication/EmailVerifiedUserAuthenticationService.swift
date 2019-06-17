//
//  EmailVerifiedUserAuthenticationService.swift
//  SwiftServe
//
//  Created by Andrew Wagner on 5/16/19.
//

import Foundation
import Swiftlier
import SQL

public struct EmailVerifiedUserAuthenticationService<User: EmailVerifiedUser>: ErrorGenerating {
    public typealias CustomizableInfo = (
        serviceName: String,
        supportEmail: String,
        bounceEmail: String,
        verifyEndpoint: String,
        resetPasswordEndpoint: String
    )

    let connection: Connection

    public init(connection: Connection) {
        self.connection = connection
    }

    public func authenticatedUser(for session: UserSession) throws -> User {
        guard let user = try self.user(withId: session.id)
            , session.isValid(for: user)
            else
        {
            throw self.error("authenticating", because: "the session is invalid")
        }

        return user
    }

    public func user(withEmail email: EmailAddress, andPassword password: String) throws -> User {
        guard let user = try self.user(withEmail: email)
            , user.passwordMatches(password)
            else
        {
            throw self.userError("logging in", because: "that email and password combination is incorrect.")
        }

        return user
    }

    @discardableResult
    public func createUser(
        email: EmailAddress,
        password: String,
        extraProperties: User.ExtraProperties,
        baseUrl: URL,
        info: CustomizableInfo
        ) throws -> User
    {
        guard try self.user(withEmail: email) == nil else {
            throw self.userError("creating user", because: "a user with that email already exists")
        }
        let salt = String(randomOfLength: 16)
        let encryptedPassword = password.encrypt(withHash: salt)

        var verificationToken: String = ""
        repeat {
            verificationToken = String(randomOfLength: 16)
        }
        while try self.user(withVerificationToken: verificationToken) != nil

        let user = User(
            email: email,
            salt: salt,
            encryptedPassword: encryptedPassword,
            emailVerificationToken: verificationToken,
            extraProperties: extraProperties
        )
        guard let row = try self.connection.execute(user.insert().returning()).rows.next() else {
            throw self.error("creating user", because: "it could not be retrieved after creation")
        }
        let saved: User = try row.decode(purpose: .create)
        try self.sendVerificationEmail(
            for: saved,
            withToken: verificationToken,
            baseUrl: baseUrl,
            info: info
        )
        return saved
    }

    @discardableResult
    public func update(
        _ user: User,
        settingEmail email: EmailAddress,
        currentPassword: String,
        password: String?,
        extraProperties: User.ExtraProperties,
        baseUrl: URL,
        info: CustomizableInfo
        ) throws -> User
    {
        var user = user
        guard currentPassword.encrypt(withHash: user.passwordSalt) == user.encryptedPassword else {
            throw self.userError("saving", because: "current password was incorrect")
        }

        if let newPassword = password {
            let salt = String(randomOfLength: 16)
            user.passwordSalt = salt
            user.encryptedPassword = newPassword.encrypt(withHash: salt)
        }

        if email != user.email {
            guard try self.user(withEmail: email) == nil else {
                throw self.userError("saving", because: "a user with that email already exists")
            }
            user.email = email
            var verificationToken: String = ""
            repeat {
                verificationToken = String(randomOfLength: 16)
            }
            while try self.user(withVerificationToken: verificationToken) != nil
            user.emailVerificationToken = verificationToken
        }

        user.update(extraProperties: extraProperties)
        try self.connection.execute(try user
            .update()
            .filtered(User.filter(forId: user.id))
        )

        if let token = user.emailVerificationToken {
            try self.sendVerificationEmail(for: user, withToken: token, baseUrl: baseUrl, info: info)
        }

        return user
    }

    public func verifyUser(withToken token: String) throws -> User {
        guard !token.isEmpty else {
            throw self.userError("verifying account", because: "this link is invalid")
        }

        guard var user = try self.user(withVerificationToken: token) else {
            throw self.userError("verifying account", because: "this link has already been used or a new link has been requested. You can always request a new link and wait for the new email to come in.")
        }

        user.emailVerificationToken = nil

        try self.connection.execute(try user
            .update()
            .filtered(User.filter(forVerificationToken: token))
        )
        return user
    }

    public func resendVerificationEmail(for user: User, baseUrl: URL, info: CustomizableInfo) throws {
        guard let token = user.emailVerificationToken else {
            throw self.userError("sending verification token", because: "you are already verified")
        }
        try self.sendVerificationEmail(for: user, withToken: token, baseUrl: baseUrl, info: info)
    }

    public func resetPasswordForUser(withEmail email: EmailAddress, baseUrl: URL, info: CustomizableInfo) throws {
        guard var user = try self.user(withEmail: email) else {
            return
        }

        let token = String(randomOfLength: 16)
        user.passwordResetToken = token
        user.passwordResetExpiration = Date.now

        try self.connection.execute(try user
            .update()
            .filtered(User.filter(forId: user.id))
        )

        let email = try self.createResetPasswordEmail(for: user, withToken: token, baseUrl: baseUrl, info: info)
        email.send()
    }

    public func user(withPasswordResetToken token: String) throws -> User? {
        let select = User.select().filtered(User.filter(forResetPasswordToken: token))
        guard let row = try self.connection.execute(select).rows.next() else {
            return nil
        }
        return try row.decode(purpose: .create)
    }


    public func setPassword(for user: User, to new: String) throws -> User {
        var user = user
        let salt = String(randomOfLength: 16)
        user.passwordSalt = salt
        user.encryptedPassword = new.encrypt(withHash: salt)
        user.passwordResetToken = nil
        user.passwordResetExpiration = nil

        try self.connection.execute(try user
            .update()
            .filtered(User.filter(forId: user.id))
        )

        return user
    }
}

private extension EmailVerifiedUserAuthenticationService {
    func user(withVerificationToken token: String) throws -> User? {
        let select = User.select().filtered(User.filter(forVerificationToken: token))
        guard let row = try self.connection.execute(select).rows.next() else {
            return nil
        }
        return try row.decode(purpose: .create)
    }

    func user(withId id: Int) throws -> User? {
        let select = User.select().filtered(User.filter(forId: id))
        guard let row = try self.connection.execute(select).rows.next() else {
            return nil
        }
        return try row.decode(purpose: .create)
    }

    func sendVerificationEmail(
        for user: User,
        withToken token: String,
        baseUrl: URL,
        info: CustomizableInfo
        ) throws
    {
        let email = try self.createVerificationEmail(
            for: user,
            withToken: token,
            baseUrl: baseUrl,
            info: info
        )
        email.send()
    }
}

// MARK: Emails

private extension EmailVerifiedUserAuthenticationService {
    func user(withEmail email: EmailAddress) throws -> User? {
        let select = User.select().filtered(User.filter(forEmail: email))
        guard let row = try self.connection.execute(select).rows.next() else {
            return nil
        }
        return try row.decode(purpose: .create)
    }

    func createVerificationEmail(
        for user: User,
        withToken token: String,
        baseUrl: URL,
        info: CustomizableInfo
        ) throws -> Email
    {
        return try Email(
            to: user.email.string,
            subject: "\(info.serviceName) - Verify Your Email",
            from: info.supportEmail,
            returnPath: info.bounceEmail,
            template: "Views/Emails/Auth/Verify",
            build: { context in
                context["link"] = baseUrl.appendingPathComponent(info.verifyEndpoint).absoluteString + "?token=\(token)"
                context["token"] = token
            }
        )
    }

    func createPasswordChangedEmail(for user: User, info: CustomizableInfo) throws -> Email {
        return try Email(
            to: user.email.string,
            subject: "\(info.serviceName) - Your Password Has Been Changed",
            from: info.supportEmail,
            template: "Views/Emails/Auth/PasswordChanged",
            build: { context in }
        )
    }

    func createResetPasswordEmail(
        for user: User,
        withToken token: String,
        baseUrl: URL,
        info: CustomizableInfo
        ) throws -> Email
    {
        return try Email(
            to: user.email.string,
            subject: "\(info.serviceName) - Reset Your Password",
            from: info.supportEmail,
            returnPath: info.bounceEmail,
            template: "Views/Emails/Auth/Reset",
            build: { context in
                context["link"] = baseUrl.appendingPathComponent(info.resetPasswordEndpoint).absoluteString + "?token=\(token)"
                context["token"] = token
                for (key, value) in user.extraDisplayProperties {
                    context[key] = value
                }
            }
        )
    }
}
