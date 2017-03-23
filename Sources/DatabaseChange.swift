//
//  DatabaseChange.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

public protocol DatabaseChange {
    var forwardQuery: String {get}
    var revertQuery: String {get}
}

public struct Reference {
    public enum Action: String {
        case none = "NO ACTION"
        case cascade = "CASCADE"
        case setNull = "SET NULL"
        case setDefault = "SET DEFAULT"
    }

    let table: String
    let field: String
    let onDelete: Action
    let onUpdate: Action

    public init(table: String, field: String, onDelete: Action = .none, onUpdate: Action = .none) {
        self.table = table
        self.field = field
        self.onDelete = onDelete
        self.onUpdate = onUpdate
    }
}

public struct FieldSpec: CustomStringConvertible {
    public enum DataType {
        case string(length: Int?)
        case timestamp
        case ipAddress
        case date
        case bool
    }

    let name: String
    let allowNull: Bool
    let isUnique: Bool
    let isPrimaryKey: Bool
    let type: DataType
    let references: Reference?

    public init(name: String, type: DataType, allowNull: Bool = true, isUnique: Bool = false, references: Reference? = nil) {
        self.name = name
        self.type = type
        self.allowNull = allowNull
        self.isUnique = isUnique
        self.isPrimaryKey = false
        self.references = references
    }

    public init(name: String, type: DataType, isPrimaryKey: Bool) {
        self.name = name
        self.type = type
        self.isPrimaryKey = isPrimaryKey
        self.references = nil

        // Setting these will mean they won't be added to the command
        self.allowNull = true
        self.isUnique = false
    }

    public var description: String {
        var description = "\(self.name) "
        switch self.type {
        case .date:
            description += "date"
        case .ipAddress:
            description += "inet"
        case .timestamp:
            description += "timestamp"
        case .string(let length):
            if let length = length {
                description += "varchar(\(length))"
            }
            else {
                description += "varchar"
            }
        case .bool:
            description += "boolean"
        }
        if isPrimaryKey {
            description += " PRIMARY KEY"
        }
        if isUnique {
            description += " UNIQUE"
        }
        if !self.allowNull {
            description += " NOT NULL"
        }
        if let references = self.references {
            description += " REFERENCES \(references.table)(\(references.field))"
            description += " ON DELETE \(references.onDelete.rawValue) ON UPDATE \(references.onUpdate.rawValue)"
        }
        return description
    }
}

public struct CreateTable: DatabaseChange {
    let name: String
    let fields: [FieldSpec]
    let primaryKey: [String]

    public init(name: String, fields: [FieldSpec], primaryKey: [String] = []) {
        self.name = name
        self.fields = fields
        self.primaryKey = primaryKey
    }

    public var forwardQuery: String {
        var query = "CREATE TABLE \(name) ("
        var specs = self.fields.map({$0.description})
        if !self.primaryKey.isEmpty {
            specs.append("PRIMARY KEY (\(self.primaryKey.joined(separator: ",")))")
        }
        query += specs.joined(separator: ",")
        query += ")"
        return query
    }

    public var revertQuery: String {
        return "DROP TABLE \(name)"
    }
}
