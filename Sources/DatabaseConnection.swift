//
//  DatabaseConnection.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/15/17.
//
//

import PostgreSQL

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
        return try self.connect().execute(query)
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

extension RowProtocolError: ReportableResponseError {
    public var status: HTTPStatus {
        return .internalServerError
    }

    public var identifier: String? {
        return "DatabaseError"
    }

    public var otherInfo: [String:String]? {
        return nil
    }
}

extension ResultError: ReportableResponseError {
    public var status: HTTPStatus {
        return .internalServerError
    }

    public var identifier: String? {
        return "DatabaseError"
    }

    public var otherInfo: [String:String]? {
        return nil
    }
}

