//
//  SwiftServeInstance.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/15/17.
//
//

import CommandLineParser
import SwiftPlusPlus
import Foundation
import TextTransformers
import SQL

public class SwiftServeInstance<S: Server, ExtraInfo: CodableType>: Router {
    public let databaseChanges: [DatabaseChange]
    public let routes: [Route]

    fileprivate let customizeCommandLineParser: ((Parser) -> ())?
    fileprivate let commandLineParser = Parser(arguments: CommandLine.arguments)

    public let domain: String
    public lazy var extraInfo = {
        return SwiftServeInstance.loadExtraInfo()
    }()

    public init(domain: String, databaseChanges: [DatabaseChange], routes: [Route], customizeCommandLineParser: ((Parser) -> ())? = nil) {
        self.databaseChanges = databaseChanges
        self.domain = domain
        self.routes = routes
        self.customizeCommandLineParser = customizeCommandLineParser

        self.loadDatabaseSetup()
        self.setupCommands()
        self.run()
    }
}

public struct SwiftServeInstanceSpec {
    public let version: (major: Int, minor: Int)
    public let domain: String
    public let extraInfoSpec: String
}

private extension SwiftServeInstance {
    var databaseName: String {
        return self.domain.replacingOccurrences(of: ".", with: "_")
    }

    var databaseRole: String {
        return self.domain.replacingOccurrences(of: ".", with: "_")
            + "_service"
    }

    static func loadDatabasePassword() -> String {
        let filePath = "database_password.string"
        if let string = try? filePath.map(FileContents()).string()
            , !string.isEmpty
        {
            return string
        }

        var password = ""
        repeat {
            print("What is the database password? ", terminator: "")
            password = readLine(strippingNewline: true) ?? ""

            if password.isEmpty {
                print("The password cannot be empty")
            }
        } while password.isEmpty

        do {
            try password.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save password: \(error)")
        }
        return password
    }

    static func loadExtraInfo() -> ExtraInfo {
        let filePath = "extra_info.json"
        if let string = try? filePath.map(FileContents()).string()
            , let data = string.data(using: .utf8)
            , let object = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
            , let extraInfo: ExtraInfo = try? NativeTypesDecoder.decodableTypeFromObject(object, mode: .saveLocally)
        {
            return extraInfo
        }

        let extraInfo: ExtraInfo = try! CommandLineDecoder.prompt()
        do {
            let object = NativeTypesEncoder.objectFromEncodable(extraInfo, mode: .saveLocally)
            let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            let string = String(data: data, encoding: .utf8) ?? ""
            try string.write(toFile: filePath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to save extra info: \(error)")
        }

        return extraInfo
    }

    func loadDatabaseSetup() {
        DatabaseSetup = DatabaseSpec(
            name: self.databaseName,
            username: self.databaseRole,
            password: SwiftServeInstance.loadDatabasePassword()
        )
    }

    func setupCommands() {
        self.commandLineParser.command(named: "info") { parser in
            let dict = try SpecDecoder.spec(forType: ExtraInfo.self)
            let spec = SwiftServeInstanceSpec(version: (5,0), domain: self.domain, extraInfoSpec: dict)
            let object = NativeTypesEncoder.objectFromEncodable(spec, mode: .saveLocally)
            let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            let string = String(data: data, encoding: .utf8) ?? ""
            print(string)
        }

        self.commandLineParser.command(named: "db") { parser in
            parser.command(named: "recreate-role") { parser in
                print("DROP DATABASE IF EXISTS \(self.databaseName);")
                print("DROP ROLE IF EXISTS \(self.databaseRole);")
                print("CREATE ROLE \(self.databaseRole) WITH LOGIN PASSWORD '\(DatabaseSetup!.password)';")
            }

            parser.command(named: "recreate") { parser in
                print("DROP DATABASE IF EXISTS \(self.databaseName);")
                print("CREATE DATABASE \(self.databaseName);")

                print("\\connect \(self.databaseName);")
                print("CREATE TABLE swift_serve (version smallint);")
                print("INSERT INTO swift_serve (version) values (0);")

                print("GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO \(self.databaseRole);")
                print("GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO \(self.databaseRole);")
            }

            parser.command(named: "migrate") { parser in
                try parser.parse()

                let connection = DatabaseConnection()
                let currentVersion = try SwiftServe.getVersion(from: connection)
                for index in currentVersion ..< self.databaseChanges.count {
                    let _ = try connection.execute(self.databaseChanges[index].forwardQuery)
                }
                let _ = try connection.execute("GRANT SELECT, USAGE ON ALL SEQUENCES IN SCHEMA public TO \(self.databaseRole);")
                let _ = try connection.execute("GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO \(self.databaseRole);")
                try SwiftServe.updateVersion(to: self.databaseChanges.count, in: connection)
            }
            try parser.parse()
        }

        self.commandLineParser.command(named: "server") { parser in
            let port = parser.int(named: "port")

            try parser.parse()

            // Load extra info now
            let _ = self.extraInfo

            #if os(Linux)
                srandom(UInt32(Date().timeIntervalSince1970))
            #endif

            print("Staring Server on \(port.parsedValue)...")
            try S(port: port.parsedValue, router: self).start()
        }

        self.customizeCommandLineParser?(self.commandLineParser)
    }

    func run() {
        do {
            try self.commandLineParser.parse()
        }
        catch {
            print("\(error)")
        }
    }
}

extension SwiftServeInstanceSpec: CodableType {
    struct Keys {
        class version: CoderKey<String> {}
        class domain: CoderKey<String> {}
        class extraInfoSpec: CoderKey<String> {}
    }

    public init(decoder: DecoderType) throws {
        let versionString = try decoder.decode(Keys.version.self)
        let components = versionString.components(separatedBy: ".")
        self.version = (Int(components[0])!, Int(components[1])!)
        self.domain = try decoder.decode(Keys.domain.self)
        self.extraInfoSpec = try decoder.decode(Keys.extraInfoSpec.self)
    }

    public func encode(_ encoder: EncoderType) {
        encoder.encode("\(self.version.major).\(self.version.minor)", forKey: Keys.version.self)
        encoder.encode(self.domain, forKey: Keys.domain.self)
        encoder.encode(self.extraInfoSpec, forKey: Keys.extraInfoSpec.self)
    }
}

private struct SwiftServe: TableProtocol {
    enum Field: String, TableField {
        static let tableName = "swift_serve"

        case version
    }

    static func updateVersion(to version: Int, in connection: DatabaseConnection) throws {
        try connection.execute(self.update([
            .version: version,
        ]))
    }

    static func getVersion(from connection: DatabaseConnection) throws -> Int {
        let result = try connection.execute(self.select)
        guard result.count >= 1 else {
            return 0
        }
        return try result[0].value("version")
    }
}
