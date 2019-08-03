//
//  EmailVerifiedUser.swift
//  SwiftServe
//
//  Created by Andrew Wagner on 5/16/19.
//

import Foundation
import Swiftlier
import SQL

public protocol EmailVerifiedUser: TableStorable, Codable {
    associatedtype ExtraProperties

    var id: Int! {get set}
    var created: Date {get}

    var email: EmailAddress {get set}
    var passwordSalt: String {get set}
    var encryptedPassword: String {get set}

    var emailVerificationToken: String? {get set}
    var passwordResetToken: String? {get set}
    var passwordResetExpiration: Date? {get set}
    var extraDisplayProperties: [String:String] {get}

    static func filter(forId id: Int) -> Predicate
    static func filter(forEmail email: EmailAddress) -> Predicate
    static func filter(forVerificationToken token: String) -> Predicate
    static func filter(forResetPasswordToken token: String) -> Predicate

    init(email: EmailAddress, salt: String, encryptedPassword: String, emailVerificationToken: String?, extraProperties: ExtraProperties)

    mutating func update(extraProperties: ExtraProperties)
}

extension EmailVerifiedUser {
    public var isVerified: Bool {
        return self.emailVerificationToken == nil
    }

    public mutating func set(password: String) throws {
        guard password.count >= 6 else {
            throw GenericSwiftlierError("setting password", because: "the password must be at least 6 characters long", byUser: true)
        }

        let salt = String(randomOfLength: 16)
        self.passwordSalt = salt
        self.encryptedPassword = password.encrypt(withHash: salt)
    }

    func passwordMatches(_ other: String) -> Bool {
        return self.encryptedPassword == other.encrypt(withHash: self.passwordSalt)
    }
}
