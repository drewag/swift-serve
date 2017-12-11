//
//  Database.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/15/17.
//
//

import SQL
import PostgreSQL
import Swiftlier

public struct DatabaseSpec {
    let name: String
    let username: String
    let password: String
}
public var DatabaseSetup: DatabaseSpec? = nil

extension PostgreSQLConnection {
    public convenience init() {
        self.init(
            host: "localhost",
            port: 5432,
            databaseName: DatabaseSetup!.name,
            username: DatabaseSetup!.username,
            password: DatabaseSetup!.password
        )
    }
}

extension SQLError: ReportableErrorConvertible, ErrorGenerating {
    public var reportableError: ReportableError {
        return self.error("executing database command", because: self.description)
    }
}
