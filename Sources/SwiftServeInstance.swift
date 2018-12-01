//
//  SwiftServeInstance.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/15/17.
//
//

import CommandLineParser
import Swiftlier
import Foundation
import SQL
import PostgreSQL

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
        case test
    }

    public let databaseChanges: [DatabaseChange]
    public let routes: [Route]
    public let allowCrossOriginRequests: Bool

    fileprivate let customizeCommandLineParser: ((Parser) -> ())?
    fileprivate let commandLineParser: Parser
    fileprivate let htmlEnabled: Bool
    fileprivate let dataDirectories: [String]
    fileprivate let blogConfiguration: BlogConfiguration?
    fileprivate let blogRouter: BlogRouter?
    fileprivate let extraSchemes: [Scheme]
    fileprivate let productionPromise: OptionPromise
    fileprivate let testPromise: OptionPromise
    fileprivate var isTesting: Bool = false

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
        guard !self.isTesting else {
            return .test
        }

        if productionPromise.wasPresent {
            return .production
        }
        else if testPromise.wasPresent {
            return .test
        }
        else {
            return .development
        }
    }

    /// Define a service instance
    ///
    /// - Parameters:
    ///   - domain: The domain the service is hosted on
    ///   - dataDirectories: Directories that contain permenant data files
    ///   - htmlEnabled: Support basic HTML service features
    ///   - assetsEnabled: Support raw assets being accessible at /assets from the Assets directory
    ///   - blogConfiguration: Configuration for a blog route
    ///   - allowCrossOriginRequests
    ///   - databaseChanges: List of changes that define the database
    ///   - routes: Root routes
    ///   - customizeCommandLineParser: Opportunity to add custom command line commands
    ///   - extraSchemes: Extra schemes to add to Xcode projects
    public init(
        domain: String,
        dataDirectories: [String] = [],
        htmlEnabled: Bool = false,
        assetsEnabled: Bool = true,
        blogConfiguration: BlogConfiguration? = nil,
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
        self.testPromise = parser.option(named: "test")
        self.allowCrossOriginRequests = allowCrossOriginRequests
        self.htmlEnabled = htmlEnabled
        self.blogConfiguration = blogConfiguration
        self.dataDirectories = dataDirectories

        var routes = routes
        if let config = blogConfiguration {
            let blogRouter = BlogRouter(configuration: config)
            var rootEndpoint = config.rootEndpoint
            if rootEndpoint.hasPrefix("/") {
                rootEndpoint.remove(at: rootEndpoint.startIndex)
            }
            if rootEndpoint.isEmpty {
                routes.insert(Route.any(router: blogRouter), at: 0)
            }
            else {
                routes.insert(Route.any(rootEndpoint, router: blogRouter), at: 0)
            }
            self.blogRouter = blogRouter
        }
        else {
            self.blogRouter = nil
        }
        if assetsEnabled {
            routes.insert(.get("assets", router: AssetRouter()), at: 0)
        }
        if htmlEnabled {
            routes.insert(.get(router: WebBasicsRouter()), at: 0)
            routes.insert(.get(router: FaviconRouter()), at: 0)
            routes.append(.get(router: PagesRouter()))
            // 404
            routes.append(.any(router: WebErrorRouter()))
        }

        self.customizeCommandLineParser = customizeCommandLineParser
        self.databaseChanges = databaseChanges
        self.domain = domain
        self.routes = routes
        self.extraSchemes = extraSchemes

        self.setupCommands()
    }

    public func preprocess(request: Request, context: inout [String : Any]) throws {
        var domain: String
        if request.host == "localhost" {
            domain = "http://localhost"
        }
        else {
            domain = "https://\(request.host)"
        }

        if let port = request.baseURL.port {
            domain += ":\(port)"
        }
        context["domain"] = domain
    }

    public func run() {
        self.isTesting = false
        do {
            try self.commandLineParser.parse(beforeExecute: {
                self.loadDatabaseSetup()
            })
        }
        catch {
            print("\(error)")
        }
    }

    public func setupTest() {
        self.isTesting = true
        self.loadDatabaseSetup()
    }
}

public struct SwiftServeInstanceSpec {
    public let version: (major: Int, minor: Int)
    public let domain: String
    public let extraInfoSpec: String
    public let extraSchemes: [Scheme]
    public let dataDirectories: [String]
}

private extension SwiftServeInstance {
    var databaseName: String {
        switch self.environment {
        case .development:
            return self.domain.replacingOccurrences(of: ".", with: "_") + "_dev"
        case .test:
            return self.domain.replacingOccurrences(of: ".", with: "_") + "_test"
        case .production:
            return self.domain.replacingOccurrences(of: ".", with: "_")
        }
    }

    var databaseRole: String {
        return self.domain.replacingOccurrences(of: ".", with: "_")
            + "_service"
    }

    static func loadDatabasePassword(for environment: Environment) -> String {
        let filePath = "database_password.string"
        if let string = try? String(contentsOfFile: filePath)
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
        case .test:
            filePath = "test_\(filePath)"
        case .production:
            break
        }
        if let string = try? String(contentsOfFile: filePath)
            , let data = string.data(using: .utf8)
            , let extraInfo = try? JSONDecoder().decode(ExtraInfo.self, from: data)
        {
            return extraInfo
        }

        let extraInfo: ExtraInfo = try! CommandLineDecoder.prompt()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(extraInfo)
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
            let spec = SwiftServeInstanceSpec(version: (5,0), domain: self.domain, extraInfoSpec: dict, extraSchemes: self.extraSchemes, dataDirectories: self.dataDirectories)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(spec)
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

                let connection = PostgreSQLConnection()

                let core = try SwiftServeInternal(from: connection)
                try self.blogRouter?.migrate(from: core, in: connection)

                let currentVersion = try SwiftServe.getVersion(from: connection)
                var newVersion = currentVersion

                defer {
                    let _ = try? SwiftServe.updateVersion(to: newVersion, in: connection)
                }

                for index in currentVersion ..< self.databaseChanges.count {
                    for query in self.databaseChanges[index].forwardQueries {
                        try connection.executeIgnoringResult(query)
                    }
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

        var generators = [StaticPagesGenerator]()


        if self.htmlEnabled {
            generators.append(WebStaticPagesGenerator())
        }
        if let config = self.blogConfiguration {
            generators.append(BlogStaticPagesGenerator(configuration: config))
        }
        self.commandLineParser.command(named: "regenerate", handler: RegenerateCommand.handler(generators: generators))

        self.blogRouter?.addCommands(to: self.commandLineParser)
        self.customizeCommandLineParser?(self.commandLineParser)
    }
}

extension SwiftServeInstanceSpec: Codable {
    enum CodingKeys: String, CodingKey {
        case version, domain, extraInfoSpec, extraSchemes, dataDirectories
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let versionString = try container.decode(String.self, forKey: .version)
        let components = versionString.components(separatedBy: ".")
        self.version = (Int(components[0])!, Int(components[1])!)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.extraInfoSpec = try container.decode(String.self, forKey: .extraInfoSpec)
        self.extraSchemes = try container.decode([Scheme].self, forKey: .extraSchemes)
        self.dataDirectories = try container.decode([String].self, forKey: .dataDirectories)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(self.version.major).\(self.version.minor)", forKey: .version)
        try container.encode(self.domain, forKey: .domain)
        try container.encode(self.extraInfoSpec, forKey: .extraInfoSpec)
        try container.encode(self.extraSchemes, forKey: .extraSchemes)
        try container.encode(self.dataDirectories, forKey: .dataDirectories)
    }
}

extension Scheme: Codable {
    enum CodingKeys: String, CodingKey {
        case name, arguments
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        self.arguments = try container.decode([String].self, forKey: .arguments)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.arguments, forKey: .arguments)
    }
}

private struct SwiftServe: TableStorable {
    static let tableName = "swift_serve"

    enum Fields: String, Field {
        case version

        var sqlFieldSpec: FieldSpec? {
            switch self {
            case .version:
                return self.spec(dataType: .smallint, allowNull: false, isUnique: false, references: nil, defaultValue: 0)
            }
        }
    }

    static func updateVersion(to version: Int, in connection: Connection) throws {
        try connection.execute(self.update([
            (.version, version),
        ]))
    }

    static func getVersion(from connection: Connection) throws -> Int {
        let result = try connection.execute(self.select())
        guard let row = result.rows.next() else {
            return 0
        }
        return try row.get(.version)
    }
}
