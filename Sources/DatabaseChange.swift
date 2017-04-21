//
//  DatabaseChange.swift
//  drewag.me
//
//  Created by Andrew J Wagner on 3/18/17.
//
//

public protocol DatabaseChange {
    var forwardQuery: String {get}
    var revertQuery: String? {get}
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

public struct Constraint: CustomStringConvertible {
    public enum Kind {
        case unique([String])
    }

    let name: String
    let kind: Kind

    public init(name: String, kind: Kind) {
        self.name = name
        self.kind = kind
    }

    public var description: String {
        var description = "CONSTRAINT \(self.name) "
        switch kind {
        case .unique(let unique):
            description += "UNIQUE ("
            description += unique.joined(separator: ",")
            description += ")"
        }
        return description
    }
}

public enum ValueKind {
    case calculated(String)
    case string(String)
    case subcommand(String)
}

public struct FieldSpec: CustomStringConvertible {
    public enum DataType {
        case string(length: Int?)
        case timestamp
        case timestampWithTimeZone
        case interval
        case ipAddress
        case date
        case bool
        case serial
        case integer
        case double
    }

    let name: String
    let allowNull: Bool
    let isUnique: Bool
    let isPrimaryKey: Bool
    let type: DataType
    let references: Reference?
    let defaultValue: ValueKind?

    public init(name: String, type: DataType, allowNull: Bool = true, isUnique: Bool = false, references: Reference? = nil, default: ValueKind? = nil) {
        self.name = name
        self.type = type
        self.allowNull = allowNull
        self.isUnique = isUnique
        self.isPrimaryKey = false
        self.references = references
        self.defaultValue = `default`
    }

    public init(name: String, type: DataType, isPrimaryKey: Bool) {
        self.name = name
        self.type = type
        self.isPrimaryKey = isPrimaryKey

        // Setting these will mean they won't be added to the command
        self.allowNull = true
        self.isUnique = false
        self.defaultValue = nil
        self.references = nil
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
        case .timestampWithTimeZone:
            description += "timestamp with time zone"
        case .string(let length):
            if let length = length {
                description += "varchar(\(length))"
            }
            else {
                description += "varchar"
            }
        case .bool:
            description += "boolean"
        case .serial:
            description += "SERIAL"
        case .integer:
            description += "integer"
        case .double:
            description += "double precision"
        case .interval:
            description += "interval"
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
        if let defaultValue = self.defaultValue {
            description += " DEFAULT "
            switch defaultValue {
            case .calculated(let calculated):
                description += calculated
            case .string(let string):
                description += "'\(string)'"
            case .subcommand(let subcommand):
                description += "(\(subcommand))"
            }
        }
        if let references = self.references {
            description += " REFERENCES \(references.table)(\(references.field))"
            description += " ON DELETE \(references.onDelete.rawValue) ON UPDATE \(references.onUpdate.rawValue)"
        }
        return description
    }
}

public struct CreateBoundedPseudoEncrypt: DatabaseChange {
    public static func callWith(value: String, max: Int) -> String {
        return "bounded_pseudo_encrypt(\(value), \(max))"
    }

    public init() {}

    public var forwardQuery: String {
        var output = ""
        output += "CREATE FUNCTION pseudo_encrypt_24(VALUE int) returns int AS $$\n"
        output += "DECLARE\n"
        output += "l1 int;\n"
        output += "l2 int;\n"
        output += "r1 int;\n"
        output += "r2 int;\n"
        output += "i int:=0;\n"
        output += "BEGIN\n"
        output += "l1:= (VALUE >> 12) & (4096-1);\n"
        output += "r1:= VALUE & (4096-1);\n"
        output += "WHILE i < 3 LOOP\n"
        output += "l2 := r1;\n"
        output += "r2 := l1 # ((((1366 * r1 + 150889) % 714025) / 714025.0) * (4096-1))::int;\n"
        output += "l1 := l2;\n"
        output += "r1 := r2;\n"
        output += "i := i + 1;\n"
        output += "END LOOP;\n"
        output += "RETURN ((l1 << 12) + r1);\n"
        output += "END;\n"
        output += "$$ LANGUAGE plpgsql strict immutable;\n"

        output += "CREATE FUNCTION bounded_pseudo_encrypt(VALUE int, MAX int) returns int AS $$\n"
        output += "BEGIN\n"
        output += "LOOP\n"
        output += "VALUE := pseudo_encrypt_24(VALUE);\n"
        output += "EXIT WHEN VALUE <= MAX;\n"
        output += "END LOOP;\n"
        output += "RETURN VALUE;\n"
        output += "END\n"
        output += "$$ LANGUAGE plpgsql strict immutable;"
        return output
    }

    public var revertQuery: String? {
        return "DROP FUNCTION bounded_pseudo_encrypt(int,int);DROP FUNCTION pseudo_encrypt_24(int)"
    }
}

public struct CreateSequence: DatabaseChange {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public var forwardQuery: String {
        return "CREATE SEQUENCE \(name)"
    }

    public var revertQuery: String? {
        return "DROP SEQUENCE \(name)"
    }
}

public struct UpdateTable: DatabaseChange {
    let name: String
    let updates: [String:ValueKind]

    public init(name: String, updates: [String:ValueKind]) {
        self.name = name
        self.updates = updates
    }

    public var forwardQuery: String {
        let updates = self.updates.map({ (column, value) in
            switch value {
            case .calculated(let caculated):
                return "\(column) = \(caculated)"
            case .string(let string):
                return "\(column) = '\(string)'"
            case .subcommand(let subcommand):
                return "\(column) = (\(subcommand))"
            }
        }).joined(separator: ", ")
        return "UPDATE \(name) SET \(updates)"
    }

    public let revertQuery: String? = nil
}

public struct CreateTable: DatabaseChange {
    let name: String
    let fields: [FieldSpec]
    let constraints: [Constraint]
    let primaryKey: [String]

    public init(name: String, fields: [FieldSpec], primaryKey: [String] = [], constraints: [Constraint] = []) {
        self.name = name
        self.fields = fields
        self.primaryKey = primaryKey
        self.constraints = constraints
    }

    public var forwardQuery: String {
        var query = "CREATE TABLE \(name) ("
        var specs = self.fields.map({$0.description})
        if !self.primaryKey.isEmpty {
            specs.append("PRIMARY KEY (\(self.primaryKey.joined(separator: ",")))")
        }
        specs += self.constraints.map({$0.description})
        query += specs.joined(separator: ",")
        query += ")"
        return query
    }

    public var revertQuery: String? {
        return "DROP TABLE \(name)"
    }
}

public struct AddColumn: DatabaseChange {
    let table: String
    let spec: FieldSpec

    public init(to table: String, with spec: FieldSpec) {
        self.table = table
        self.spec = spec
    }

    public var forwardQuery: String {
        return "ALTER TABLE \(table) ADD COLUMN \(spec.description)"
    }

    public var revertQuery: String? {
        return "DROP COLUMN \(self.spec.name)"
    }
}

public struct InsertRow: DatabaseChange {
    let table: String
    let values: [String]

    public init(into table: String, values: [String]) {
        self.table = table
        self.values = values
    }

    public var forwardQuery: String {
        var query = "INSERT INTO \(self.table) VALUES ("
        query += self.values.joined(separator: ",")
        query += ")"
        return query
    }

    public var revertQuery: String? {
        return nil
    }
}
