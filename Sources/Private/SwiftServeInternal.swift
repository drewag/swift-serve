//
//  SwiftServeInternalCore.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

import SQL
import Swiftlier

private struct SwiftServeInternalCore: TableStorable, Codable {
    typealias Fields = CodingKeys
    static let tableName = "swift_serve_internal"

    enum CodingKeys: Field {
        case version

        var sqlFieldSpec: FieldSpec? {
            switch self {
            case .version:
                return spec(dataType: .integer, allowNull: false, defaultValue: 0)
            }
        }
    }

    var version: Int

    init(from connection: Connection) throws {
        for query in SwiftServeInternalCore.create(ifNotExists: true, fields: [.version]).forwardQueries {
            try connection.executeIgnoringResult(query)
        }

        let result = try connection.execute(SwiftServeInternalCore.select().limited(to: 1))
        if let row = result.rows.next() {
            let existing: SwiftServeInternalCore = try row.decode(purpose: .create)
            self.version = existing.version
        }
        else {
            self.version = 0
            try connection.execute(try self.insert())
        }
    }
}

struct SwiftServeInternal: TableStorable, Codable {
    typealias Fields = CodingKeys
    static let tableName = "swift_serve_internal"

    enum CodingKeys: Field {
        case version
        case subscribers

        var sqlFieldSpec: FieldSpec? {
            switch self {
            case .version:
                return spec(dataType: .integer, allowNull: false, defaultValue: 0)
            case .subscribers:
                return spec(dataType: .bool, allowNull: false, defaultValue: false)
            }
        }
    }

    let version: Int
    var subscribers: Bool

    init(from connection: Connection) throws {
        let core = try SwiftServeInternalCore(from: connection)
        try SwiftServeInternal.migrate(connection, from: core)

        let result = try connection.execute(SwiftServeInternal.select().limited(to: 1))
        guard let row = result.rows.next() else {
            throw GenericSwiftlierError("migrating", because: "an internal swift serve version was not found")
        }

        self = try row.decode(purpose: .create)
    }
}

private extension SwiftServeInternal {
    static func migrate(_ connection: Connection, from core: SwiftServeInternalCore) throws {
        var core = core
        let max = 1
        for step in core.version ..< max {
            let queries: [AnyQuery]
            switch step {
            case 0:
                queries = SwiftServeInternal.addColumn(forField: .subscribers).forwardQueries
            default:
                throw GenericSwiftlierError("migrating", because: "invalid core version")
            }
            for query in queries {
                try connection.executeIgnoringResult(query)
            }
            core.version = step + 1
            try connection.execute(try core.update())
        }
    }
}
