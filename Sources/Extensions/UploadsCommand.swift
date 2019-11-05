//
//  UploadsCommand.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/4/19.
//

import Foundation
import CommandLineParser
import Swiftlier
import OnBeatLib
import SQL
import PostgreSQL

struct UploadsCommand: CommandHandler {
    static let name: String = "uploads"
    static let shortDescription: String? = "Manage uploads"
    static let longDescription: String? = nil

    static func handler(parser: Parser) throws {
        parser.command(named: "move-to-db") { parser in
            let directory = try FileSystem.default.workingDirectory.subdirectory("Uploads")
            let connection: Connection = PostgreSQLConnection()
            for path in try directory.contents() {
                guard let file = path.file else {
                    continue
                }
                print("Processing \(path.basename)...", terminator: "")

                let record = UploadRecord(id: file.name, content: try file.contents(), created: try file.lastModified())
                try connection.execute(try record.insert())
                try file.delete()

                print("done")
            }
        }
        try parser.parse()
    }
}
