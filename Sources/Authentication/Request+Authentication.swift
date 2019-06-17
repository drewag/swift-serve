//
//  Request+Authentication.swift
//  UniteWCSLib
//
//  Created by Andrew J Wagner on 5/20/19.
//

extension Request {
    public func user<User: EmailVerifiedUser>() -> User? {
        return try? self.unverifiedUser()
    }

    public func unverifiedUser<User: EmailVerifiedUser>() throws -> User {
        guard let session = try UserSession(request: self) else {
            throw self.networkError("authenticating", withStatus: .badRequest, because: "a session has not been specified")
        }

        let service = EmailVerifiedUserAuthenticationService<User>(connection: self.databaseConnection)
        return try service.authenticatedUser(for: session)
    }

    public func verifiedUser<User: EmailVerifiedUser>() throws -> User {
        let user: User = try self.unverifiedUser()
        guard user.isVerified else {
            throw self.networkError("authenticating", withStatus: .forbidden, because: "you have not verified your email yet")
        }
        return user
    }
}
