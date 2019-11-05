//
//  UploadRecord.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/4/19.
//

import Foundation
import SQL

public struct UploadRecord: TableStorable, Codable {
    public static let tableName = "uploads"

    public enum CodingKeys: String, CodingKey {
        case id, content, created
    }

    public typealias Fields = CodingKeys

    let id: String
    let content: Data
    let created: Date
}

extension UploadRecord.CodingKeys: Field {
    public var sqlFieldSpec: FieldSpec? {
        switch self {
        case .id:
            return self.spec(dataType: .string(length: nil), isPrimaryKey: true)
        case .content:
            return self.spec(dataType: .data, allowNull: false)
        case .created:
            return self.spec(dataType: .timestamp, allowNull: false)
        }
    }
}
