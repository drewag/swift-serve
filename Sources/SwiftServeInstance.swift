//
//  SwiftServeInstance.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/15/17.
//
//

import CommandLineParser
import Swiftlier
import SwiftlierCLI
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

public enum SwiftServiceEnvironment {
    case production
    case development
    case test

    public func databaseName(from spec: SwiftServeInstanceSpec) -> String {
        guard let custom = spec.databaseRootName else {
            return self.databaseName(fromDomain: spec.domain)
        }
        return self.databaseName(fromRoot: custom)
    }

    public func databaseRole(from spec: SwiftServeInstanceSpec) -> String {
        guard let custom = spec.databaseRootName else {
            return self.databaseRole(fromDomain: spec.domain)
        }
        return self.databaseRole(fromRoot: custom)
    }
}

public class SwiftServeInstance<S: Server, ExtraInfo: Codable>: Router {
    public let databaseChanges: [DatabaseChange]?
    public let routes: [Route]
    public let allowCrossOriginRequests: Bool
    public let webConfiguration: WebConfiguration?

    fileprivate let customizeCommandLineParser: ((Parser) -> ())?
    fileprivate let commandLineParser: Parser
    fileprivate let dataDirectories: [String]
    fileprivate let blogConfiguration: BlogConfiguration?
    fileprivate let blogRouter: BlogRouter?
    fileprivate let extraSchemes: [Scheme]
    fileprivate let productionPromise: OptionPromise
    fileprivate let testPromise: OptionPromise
    fileprivate var isTesting: Bool = false

    public let domain: String
    public let customDatabaseName: String?
    private var loadedExtraInfo: ExtraInfo?
    public var extraInfo: ExtraInfo {
        guard let loadedExtraInfo = self.loadedExtraInfo else {
            do {
                let loaded = try SwiftServeInstance.loadExtraInfo(for: self.environment, contents: nil)
                self.loadedExtraInfo = loaded
                return loaded
            }
            catch {
                fatalError("\(error)")
            }
        }

        return loadedExtraInfo
    }
    public var environment: SwiftServiceEnvironment {
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

    @available (*, deprecated)
    public convenience init(
        domain: String,
        dataDirectories: [String] = [],
        htmlEnabled: Bool,
        assetsEnabled: Bool = true,
        blogConfiguration: BlogConfiguration? = nil,
        allowCrossOriginRequests: Bool = false,
        databaseChanges: [DatabaseChange]?,
        routes: [Route],
        customizeCommandLineParser: ((Parser) -> ())? = nil,
        extraSchemes: [Scheme] = []
        )
    {
        self.init(
            domain: domain,
            dataDirectories: dataDirectories,
            assetsEnabled: assetsEnabled,
            webConfiguration: htmlEnabled ? WebConfiguration(viewSubdirectory: "") : nil,
            blogConfiguration: blogConfiguration,
            allowCrossOriginRequests: allowCrossOriginRequests,
            databaseChanges: databaseChanges,
            routes: routes,
            customizeCommandLineParser: customizeCommandLineParser,
            extraSchemes: extraSchemes
        )
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
        databaseName: String? = nil,
        dataDirectories: [String] = [],
        assetsEnabled: Bool = true,
        webConfiguration: WebConfiguration? = nil,
        blogConfiguration: BlogConfiguration? = nil,
        allowCrossOriginRequests: Bool = false,
        databaseChanges: [DatabaseChange]?,
        routes: [Route],
        customizeCommandLineParser: ((Parser) -> ())? = nil,
        extraSchemes: [Scheme] = []
        )
    {
        let parser = Parser(arguments: CommandLine.arguments)
        self.customDatabaseName = databaseName
        self.commandLineParser = parser
        self.productionPromise = parser.option(named: "prod")
        self.testPromise = parser.option(named: "test")
        self.allowCrossOriginRequests = allowCrossOriginRequests
        self.webConfiguration = webConfiguration
        self.blogConfiguration = blogConfiguration
        self.dataDirectories = dataDirectories

        var routes = routes
        if let config = blogConfiguration {
            let blogRouter = BlogRouter(configuration: config)
            var rootEndpoint = config.rootEndpoint
            if rootEndpoint.hasPrefix("/") {
                rootEndpoint.remove(at: rootEndpoint.startIndex)
            }
            if rootEndpoint.hasSuffix("/") {
                rootEndpoint.removeLast()
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
        if let config = webConfiguration {
            routes.insert(.get(router: WebBasicsRouter(configuration: config)), at: 0)
            routes.insert(.get(router: FaviconRouter(configuration: config)), at: 0)
            routes.append(.get(router: PagesRouter(configuration: config)))
            // 404
            routes.append(.any(router: WebErrorRouter(configuration: config)))
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
                try self.loadDatabaseSetup()
            })
        }
        catch {
            print("\(error)")
        }
    }

    public func setupTest() {
        self.isTesting = true
        try! self.loadDatabaseSetup()
    }
}

public struct SwiftServeInstanceSpec {
    public let version: (major: Int, minor: Int)
    public let domain: String
    public let extraInfoSpec: String
    public let extraSchemes: [Scheme]
    public let dataDirectories: [String]
    public let databaseRootName: String?
}

private extension SwiftServeInstance {
    func spec() throws -> SwiftServeInstanceSpec {
        let dict = try SpecDecoder.spec(forType: ExtraInfo.self)
        return SwiftServeInstanceSpec(
            version: (5,0),
            domain: self.domain,
            extraInfoSpec: dict,
            extraSchemes: self.extraSchemes,
            dataDirectories: self.dataDirectories,
            databaseRootName: self.customDatabaseName ?? self.domain.replacingOccurrences(of: ".", with: "_")
        )
    }

    var databaseName: String {
        guard let name = self.customDatabaseName else {
            return self.environment.databaseName(fromDomain: self.domain)
        }
        return self.environment.databaseName(fromRoot: name)
    }

    var databaseRole: String {
        guard let name = self.customDatabaseName else {
            return self.environment.databaseRole(fromDomain: self.domain)
        }
        return self.environment.databaseRole(fromRoot: name)
    }

    static func loadDatabasePassword(for environment: SwiftServiceEnvironment) throws -> String {
        let newPath = self.pathForDatabasePassword(old: false)
        let oldPath = self.pathForDatabasePassword(old: true)
        guard let string = (try? String(contentsOfFile: newPath)) ?? (try? String(contentsOfFile: oldPath))
            , !string.isEmpty
            else
        {
            throw GenericSwiftlierError("loading database password", because: "it is invalid. Please run config command.")
        }

        return string
    }

    static func pathForExtraInfo(for environment: SwiftServiceEnvironment, old: Bool) -> String {
        var fileName = "extra_info.json"
        switch environment {
        case .development:
            fileName = "dev_\(fileName)"
        case .test:
            fileName = "test_\(fileName)"
        case .production:
            break
        }
        if old {
            return fileName
        }
        else {
            return "Config/\(fileName)"
        }
    }

    static func pathForDatabasePassword(old: Bool) -> String {
        var path = "database_password.string"
        if !old {
            path = "Config/\(path)"
        }
        return path
    }

    static func loadExtraInfo(for environment: SwiftServiceEnvironment, contents: String?) throws -> ExtraInfo {
        let oldPath = self.pathForExtraInfo(for: environment, old: true)
        let newPath = self.pathForExtraInfo(for: environment, old: false)
        guard let string = contents ?? (try? String(contentsOfFile: newPath)) ?? (try? String(contentsOfFile: oldPath))
            , let data = string.data(using: .utf8)
            , let extraInfo = try? JSONDecoder().decode(ExtraInfo.self, from: data)
            else
        {
            throw GenericSwiftlierError("loading config", because: "it is invalid. Please run config command.")
        }
        return extraInfo
    }

    static func loadPartialExtraInfo(for environment: SwiftServiceEnvironment, contents: String?) -> [String:String] {
        let oldPath = self.pathForExtraInfo(for: environment, old: true)
        let newPath = self.pathForExtraInfo(for: environment, old: false)
        guard let string = contents ?? (try? String(contentsOfFile: newPath)) ?? (try? String(contentsOfFile: oldPath))
            , let data = string.data(using: .utf8)
            , let partial = try? JSONDecoder().decode([String:String].self, from: data)
            else
        {
            return [:]
        }
        return partial
    }

    static func configExtraInfo(for environment: SwiftServiceEnvironment, contents: String?, askAboutReconfigure: Bool) -> String? {
        if nil != (try? self.loadExtraInfo(for: environment, contents: contents)) {
            guard askAboutReconfigure else {
                return contents
            }
            print("Extra info is already configured, would you like to override it? (y/N) ", terminator: "")
            let response = readLine(strippingNewline: true) ?? ""
            guard response.lowercased() == "y" else {
                return contents
            }
        }

        let filePath = self.pathForExtraInfo(for: environment, old: false)
        let extraInfo: ExtraInfo = try! CommandLineDecoder.prompt(defaults: self.loadPartialExtraInfo(for: environment, contents: contents))
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(extraInfo)
            let string = String(data: data, encoding: .utf8) ?? ""
            if contents == nil {
                try string.write(toFile: filePath, atomically: true, encoding: .utf8)
            }
            return string
        } catch {
            print("Failed to save extra info: \(error)")
            return nil
        }
    }

    static func configDatabasePassword(for environment: SwiftServiceEnvironment, askAboutReconfigure: Bool) {
        if nil != (try? self.loadDatabasePassword(for: environment)) {
            guard askAboutReconfigure else {
                return
            }
            print("A database password is already configured, would you like to override it? (y/N) ", terminator: "")
            let response = readLine(strippingNewline: true) ?? ""
            guard response.lowercased() == "y" else {
                return
            }
        }

        let filePath = self.pathForDatabasePassword(old: false)
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
    }

    func loadDatabaseSetup() throws {
        DatabaseSetup = DatabaseSpec(
            name: self.databaseName,
            username: self.databaseRole,
            password: try SwiftServeInstance.loadDatabasePassword(for: self.environment)
        )
    }

    func setupCommands() {
        self.commandLineParser.command(named: "info") { parser in
            try parser.parse()

            let spec = try self.spec()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(spec)
            let string = String(data: data, encoding: .utf8) ?? ""
            print(string)
        }

        self.commandLineParser.command(named: "config") { parser in
            let contentsPromise = parser.optionalString(named: "contents")
            let noPassword = parser.option(named: "no-password", abbreviatedWith: "p")
            let noReconfigure = parser.option(named: "no-reconfigure", abbreviatedWith: "r")

            try parser.parse()

            if !noPassword.wasPresent {
                type(of: self).configDatabasePassword(for: self.environment, askAboutReconfigure: !noReconfigure.wasPresent)
            }

            let contents = contentsPromise.parsedValue
            if let new = type(of: self).configExtraInfo(for: self.environment, contents: contents, askAboutReconfigure: !noReconfigure.wasPresent) {
                if contents != nil {
                    print(new)
                }
            }
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

                guard let databaseChanges = self.databaseChanges else {
                    print("Nothing to migrate")
                    return
                }

                let connection = PostgreSQLConnection()

                let core = try SwiftServeInternal(from: connection)
                try self.blogRouter?.migrate(from: core, in: connection)

                let currentVersion = try SwiftServe.getVersion(from: connection)
                var newVersion = currentVersion

                defer {
                    let _ = try? SwiftServe.updateVersion(to: newVersion, in: connection)
                }

                for index in currentVersion ..< databaseChanges.count {
                    for query in databaseChanges[index].forwardQueries {
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
            var errorViewRoot = "Views/"
            if let config = self.webConfiguration, !config.viewRoot.isEmpty {
                errorViewRoot += config.viewRoot + "/"
            }
            errorViewRoot += "Errors/"
            var server = try S(port: port.parsedValue, router: self, errorViewRoot: errorViewRoot)
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


        if let config = self.webConfiguration {
            generators.append(WebStaticPagesGenerator(configuration: config))
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
        case version, domain, extraInfoSpec, extraSchemes, dataDirectories, databaseRootName
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let versionString = try container.decode(String.self, forKey: .version)
        let components = versionString.components(separatedBy: ".")
        self.version = (Int(components[0])!, Int(components[1])!)
        self.domain = try container.decode(String.self, forKey: .domain)
        self.extraInfoSpec = try container.decode(String.self, forKey: .extraInfoSpec)
        self.extraSchemes = try container.decode([Scheme].self, forKey: .extraSchemes)
        self.dataDirectories = try container.decodeIfPresent([String].self, forKey: .dataDirectories) ?? []
        self.databaseRootName = try container.decodeIfPresent(String.self, forKey: .databaseRootName)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(self.version.major).\(self.version.minor)", forKey: .version)
        try container.encode(self.domain, forKey: .domain)
        try container.encode(self.extraInfoSpec, forKey: .extraInfoSpec)
        try container.encode(self.extraSchemes, forKey: .extraSchemes)
        try container.encode(self.dataDirectories, forKey: .dataDirectories)
        try container.encode(self.databaseRootName, forKey: .databaseRootName)
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

private extension SwiftServiceEnvironment {
    func databaseName(fromDomain domain: String) -> String {
        return self.databaseName(fromRoot: domain.replacingOccurrences(of: ".", with: "_"))
    }

    func databaseName(fromRoot root: String) -> String {
        switch self {
        case .development:
            return root + "_dev"
        case .test:
            return root + "_test"
        case .production:
            return root
        }
    }

    func databaseRole(fromDomain domain: String) -> String {
        return self.databaseRole(fromRoot: domain.replacingOccurrences(of: ".", with: "_"))
    }

    func databaseRole(fromRoot root: String) -> String {
        return root + "_service"
    }
}
