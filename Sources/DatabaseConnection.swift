//
//  DatabaseConnection.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/15/17.
//
//

import PostgreSQL
import Swiftlier

public struct DatabaseSpec {
    let name: String
    let username: String
    let password: String
}
public var DatabaseSetup: DatabaseSpec? = nil

public final class DatabaseConnection {
    fileprivate let connection = Connection(info: Connection.ConnectionInfo(
        host: "localhost",
        port: 5432,
        databaseName: DatabaseSetup!.name,
        username: DatabaseSetup!.username,
        password: DatabaseSetup!.password
    ))
    fileprivate var isConnected: Bool = false

    public init() {}

    public func execute(_ query: Select) throws -> Result {
        return try self.connect().execute(query)
    }

    @discardableResult
    public func execute(_ query: Update) throws -> Result {
        return try self.connect().execute(query)
    }

    @discardableResult
    public func execute(_ query: Insert, returnInsertedRows: Bool = false) throws -> Result {
        return try self.connect().execute(query, returnInsertedRows: returnInsertedRows)
    }

    @discardableResult
    public func execute(_ query: Delete) throws -> Result {
        return try self.connect().execute(query)
    }

    public func execute(_ string: String) throws -> Result {
        return try self.connect().execute(string)
    }
}

private extension DatabaseConnection {
    func connect() throws -> Connection {
        guard !self.isConnected else {
            return self.connection
        }

        try self.connection.open()
        self.isConnected = true
        return self.connection
    }
}


extension ResultError: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .badStatus(status, string):
            var description = ""
            switch status {
            case .EmptyQuery:
                description += "Empty Query"
            case .CommandOK:
                description += "Command OK"
            case .TuplesOK:
                description += "Tuples OK"
            case .CopyOut:
                description += "Copy Out"
            case .CopyIn:
                description += "Copy In"
            case .BadResponse:
                description += "Bad Response"
            case .NonFatalError:
                description += "Non Fatal Error"
            case .FatalError:
                description += "Fatal Error"
            case .CopyBoth:
                description += "Copy Both"
            case .SingleTuple:
                description += "Single Tuple"
            case .Unknown:
                description += "Unknown"
            }
            return "\(description): \(string)"
        }
    }
}

extension RowProtocolError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .expectedQualifiedField(let field):
            return "Expected value for '\(field.qualifiedName)'"
        case .unexpectedNilValue(let field):
            return "Unexpected nil value for '\(field.qualifiedName)'"
        }
    }
}

extension RowProtocolError: ReportableErrorConvertible, ErrorGenerating {
    public var reportableError: ReportableError {
        let reason: ErrorReason
        switch self {
        case .expectedQualifiedField(let field):
            reason = ErrorReason("there is no column for '\(field)'")
        case .unexpectedNilValue(let field):
            reason = ErrorReason("'\(field)' is null")
        }
        return ReportableError(from: type(of: self), by: .system, doing: "loading value from database", because: reason)
    }
}

extension ResultError: ReportableErrorConvertible, ErrorGenerating {
    public var reportableError: ReportableError {
        let reason: ErrorReason
        switch self {
        case .badStatus(let status, let message):
            switch status {
            case .EmptyQuery:
                reason = ErrorReason("query was empty")
            case .CommandOK, .TuplesOK, .CopyOut, .CopyIn, .CopyBoth, .SingleTuple:
                reason = ErrorReason("query had no error")
            case .BadResponse:
                reason = ErrorReason("query had bad response: \(message)")
            case .NonFatalError:
                reason = ErrorReason("query had non-fatal error: \(message)")
            case .FatalError:
                reason = ErrorReason("query had fatal error: \(message)")
            case .Unknown:
                reason = ErrorReason("query had unknown error: \(message)")
            }
        }
        return ReportableError(from: type(of: self), by: .system, doing: "executing database query", because: reason)
    }
}

