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
        case id, content
    }

    public typealias Fields = CodingKeys

    let id: String
    let content: Data
}

extension UploadRecord.CodingKeys: Field {
    public var sqlFieldSpec: FieldSpec? {
        switch self {
        case .id:
            return self.spec(dataType: .string(length: nil), isPrimaryKey: true)
        case .content:
            return self.spec(dataType: .data, allowNull: false)
        }
    }
}
