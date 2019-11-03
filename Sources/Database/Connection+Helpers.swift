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
    let host: String
    let name: String
    let username: String
    let password: String
}
public var DatabaseSetup: DatabaseSpec? = nil

extension PostgreSQLConnection {
    public convenience init() {
        self.init(
            host: DatabaseSetup!.host,
            port: 5432,
            databaseName: DatabaseSetup!.name,
            username: DatabaseSetup!.username,
            password: DatabaseSetup!.password
        )
    }
}
