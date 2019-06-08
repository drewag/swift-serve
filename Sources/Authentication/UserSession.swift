//
//  UserSession.swift
//  SwiftServe
//
//  Created by Andrew Wagner on 5/17/19.
//

import Foundation
import Swiftlier

public struct UserSession: ErrorGenerating {
    public let id: Int
    let digest: String
    let created: Date
    let expiration: String
    var expirationDate: Date? {
        if self.expiration != "INF", let timeInterval = TimeInterval(self.expiration) {
            return Date(timeIntervalSince1970: timeInterval)
        }
        else {
            return nil
        }
    }

    var age: TimeInterval {
        return Date.now.timeIntervalSince(self.created)
    }

    public var isExpired: Bool {
        guard let expiration = self.expirationDate else {
            return false
        }
        return expiration < Date.now
    }

    public var string: String {
        return "exp=\(expiration)&id=\(id)&created=\(self.created.timeIntervalSince1970)&digest=\(digest)"
    }

    public init(string: String) throws {
        let values = UserSession.values(fromString: string)
        guard let idString = values["id"]
            , let id = Int(idString)
            , let digest = values["digest"]
            , let expiration = values["exp"]
            , let createdString = values["created"]
            , let createdTimeInterval = TimeInterval(createdString)
            else
        {
            throw UserSession.error("parsing session", because: "it is invalid")
        }
        self.id = id
        self.digest = digest
        self.expiration = expiration
        self.created = Date(timeIntervalSince1970: createdTimeInterval)
    }

    public init?(request: Request) throws {
        for (name, value) in request.cookies {
            if name == "session" {
                try self.init(string: value)
                return
            }
        }
        return nil
    }

    public init<User: EmailVerifiedUser>(user: User, expiringInSeconds seconds: Int?) {
        self.init(id: user.id, salt: user.passwordSalt, expiringInSeconds: seconds)
    }

    init(id: Int, salt: String, expiringInSeconds seconds: Int?) {
        let expiration: String
        if let seconds = seconds {
            expiration = String(Int(Date.now.timeIntervalSince1970) + seconds)
        }
        else {
            expiration = "INF"
        }
        self.id = id
        self.digest = UserSession.encryptedDigest(expiration: expiration, salt: salt)
        self.expiration = expiration
        self.created = Date()
    }

    func isValid<User: EmailVerifiedUser>(for user: User) -> Bool {
        let correctDigest = type(of: self).encryptedDigest(expiration: expiration, salt: user.passwordSalt)
        return self.digest == correctDigest
    }
}

private extension UserSession {
    static func values(fromString string: String) -> [String:String] {
        var values = [String:String]()
        var key = ""
        var value = ""
        var finishedKey = false
        for character in string {
            if finishedKey {
                if character == "&" {
                    values[key] = value
                    key = ""
                    value = ""
                    finishedKey = false
                }
                else {
                    value.append(character)
                }
            }
            else {
                if character == "=" {
                    finishedKey = true
                }
                else {
                    key.append(character)
                }
            }
        }

        values[key] = value

        return values
    }

    static func encryptedDigest(expiration: String, salt: String) -> String {
        let rawKey = "kYfAbf@DEFEJ4YZTczNXk[RQjp3,DTh2GGCAZX#ZQ4pp]REFU2"
        var key = ""
        for (index, character)  in rawKey.enumerated() {
            if index % 2 == 0 {
                key.append(character)
            }
        }
        let encrypted = "exp=\(expiration)&salt=\(salt)".encrypt(withHash: key)
        var escaped = ""

        for character in encrypted {
            switch character {
            case "&":
                escaped.append("%")
            case "=":
                escaped.append("-")
            default:
                escaped.append(character)
            }
        }

        return escaped
    }
}
