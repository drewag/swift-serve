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

public struct Scheme {
    public let name: String
    public let arguments: [String]

    public init(name: String, arguments: [String]) {
        self.name = name
        self.arguments = arguments
    }
}

public class SwiftServeInstance<S: Server, ExtraInfo: Codable>: Router {
    public enum Environment {
        case production
        case development
    }

    public let databaseChanges: [DatabaseChange]
    public let routes: [Route]
    public let allowCrossOriginRequests: Bool

    fileprivate let customizeCommandLineParser: ((Parser) -> ())?
    fileprivate let commandLineParser: Parser
    fileprivate let extraSchemes: [Scheme]
    fileprivate let productionPromise: OptionPromise

    public let domain: String
    private var loadedExtraInfo: ExtraInfo?
    public var extraInfo: ExtraInfo {
        guard let loadedExtraInfo = self.loadedExtraInfo else {
            let loaded = SwiftServeInstance.loadExtraInfo(for: self.environment)
            self.loadedExtraInfo = loaded
            return loaded
        }

        return loadedExtraInfo
    }
    public var environment: Environment {
        if productionPromise.wasPresent {
            return .production
        }
        else {
            return .development
        }
    }

    public init(
        domain: String,
        allowCrossOriginRequests: Bool = false,
        databaseChanges: [DatabaseChange],
        routes: [Route],
        customizeCommandLineParser: ((Parser) -> ())? = nil,
        extraSchemes: [Scheme] = []
        )
    {
        let parser = Parser(arguments: CommandLine.arguments)
        self.commandLineParser = parser
        self.productionPromise = parser.option(named: "prod")
        self.allowCrossOriginRequests = allowCrossOriginRequests

        self.databaseChanges = databaseChanges
        self.domain = domain
        self.routes = routes
        self.customizeCommandLineParser = customizeCommandLineParser
        self.extraSchemes = extraSchemes

        self.setupCommands()
    }

    public func run() {
        do {
            try self.commandLineParser.parse(beforeExecute: {
                self.loadDatabaseSetup()
            })
        }
        catch {
            print("\(error)")
        }
    }
}

public struct SwiftServeInstanceSpec {
    public let version: (major: Int, minor: Int)
    public let domain: String
    public let extraInfoSpec: String
    public let extraSchemes: [Scheme]
}

private extension SwiftServeInstance {
    var databaseName: String {
        switch self.environment {
        case .development:
            return self.domain.replacingOccurrences(of: ".", with: "_") + "_dev"
        case .production:
            return self.domain.replacingOccurrences(of: ".", with: "_")
        }
    }

    var databaseRole: String {
        return self.domain.replacingOccurrences(of: ".", with: "_")
            + "_service"
    }

    static func loadDatabasePassword(for environment: Environment) -> String {
        var filePath = "database_password.string"
        switch environment {
        case .development:
            filePath = "dev_\(filePath)"
        case .production:
            break
        }
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

    static func loadExtraInfo(for environment: Environment) -> ExtraInfo {
        var filePath = "extra_info.json"
        switch environment {
        case .development:
            filePath = "dev_\(filePath)"
        case .production:
            break
        }
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
            password: SwiftServeInstance.loadDatabasePassword(for: self.environment)
        )
    }

    func setupCommands() {
        self.commandLineParser.command(named: "info") { parser in
            try parser.parse()

            let dict = try SpecDecoder.spec(forType: ExtraInfo.self)
            let spec = SwiftServeInstanceSpec(version: (5,0), domain: self.domain, extraInfoSpec: dict, extraSchemes: self.extraSchemes)
            let object = NativeTypesEncoder.objectFromEncodable(spec, mode: .saveLocally)
            let data = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            let string = String(data: data, encoding: .utf8) ?? ""
            print(string)
        }

        self.commandLineParser.command(named: "db") { parser in
            parser.command(named: "recreate-role") { parser in
                try parser.parse()

                print("SET client_min_messages TO WARNING;")
                print("DROP DATABASE IF EXISTS \(self.databaseName);")
                print("DROP ROLE IF EXISTS \(self.databaseRole);")
                print("CREATE ROLE \(self.databaseRole) WITH LOGIN PASSWORD '\(DatabaseSetup!.password)';")
            }

            parser.command(named: "recreate") { parser in
                try parser.parse()

                print("SET client_min_messages TO WARNING;")
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
                var newVersion = currentVersion

                defer {
                    let _ = try? SwiftServe.updateVersion(to: newVersion, in: connection)
                }

                for index in currentVersion ..< self.databaseChanges.count {
                    let _ = try connection.execute(self.databaseChanges[index].forwardQuery)
                    newVersion += 1
                }
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

            print("Staring Server on \(port.parsedValue) using database \(DatabaseSetup!.name)...")
            var server = try S(port: port.parsedValue, router: self)
            if self.allowCrossOriginRequests {
                server.postProcessResponse = { response in
                    response.headers["Access-Control-Allow-Origin"] = "*"
                    response.headers["Access-Control-Allow-Methods"] = "POST, PUT, GET, HEAD, DELETE, OPTIONS"
                    response.headers["Access-Control-Allow-Headers"] = "Access-Control-Request-Headers"
                }
            }
            try server.start()
        }

        self.customizeCommandLineParser?(self.commandLineParser)
    }
}

extension SwiftServeInstanceSpec: Codable {
    struct Keys {
        class version: CoderKey<String> {}
        class domain: CoderKey<String> {}
        class extraInfoSpec: CoderKey<String> {}
        class extraSchemes: CoderKey<Scheme> {}
    }

    public init(decoder: Decoder) throws {
        let versionString = try decoder.decode(Keys.version.self)
        let components = versionString.components(separatedBy: ".")
        self.version = (Int(components[0])!, Int(components[1])!)
        self.domain = try decoder.decode(Keys.domain.self)
        self.extraInfoSpec = try decoder.decode(Keys.extraInfoSpec.self)
        self.extraSchemes = try decoder.decodeArray(Keys.extraSchemes.self)
    }

    public func encode(_ encoder: Encoder) {
        encoder.encode("\(self.version.major).\(self.version.minor)", forKey: Keys.version.self)
        encoder.encode(self.domain, forKey: Keys.domain.self)
        encoder.encode(self.extraInfoSpec, forKey: Keys.extraInfoSpec.self)
        encoder.encode(self.extraSchemes, forKey: Keys.extraSchemes.self)
    }
}

extension Scheme: Codable {
    struct Keys {
        class name: CoderKey<String> {}
        class arguments: CoderKey<String> {}
    }

    public init(decoder: Decoder) throws {
        self.name = try decoder.decode(Keys.name.self)
        self.arguments = try decoder.decodeArray(Keys.arguments.self)
    }

    public func encode(_ encoder: Encoder) {
        encoder.encode(self.name, forKey: Keys.name.self)
        encoder.encode(self.arguments, forKey: Keys.arguments.self)
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
