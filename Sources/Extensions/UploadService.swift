//
//  UploadService.swift
//  web
//
//  Created by Andrew J Wagner on 7/18/17.
//
//

import Foundation
import Swiftlier
import SQL

public struct UploadIdentifier {
    public let string: String

    public init(_ string: String) {
        self.string = string
    }

    public init?(_ string: String?) {
        guard let string = string else {
            return nil
        }
        self.string = string
    }
}

public struct UploadService: Router {
    public enum Storage {
        case fileSystem, database
    }

    let storage: Storage

    public var routes: [Route] {
        return [
            .getWithParam(consumeEntireSubPath: false, handler: { (request, identifier: String) in
                return try UploadService.response(to: request, for: identifier, storage: self.storage)
            }),
        ]
    }

    public init(storage: Storage = .fileSystem) {
        self.storage = storage
    }

    public static func saveFile(containing data: Data, storage: Storage = .fileSystem, connection: Connection? = nil) throws -> UploadIdentifier {
        switch storage {
        case .fileSystem:
            var id: UUID
            var path: Path
            repeat {
                id = UUID()
                path = try self.directory().file(id.uuidString)
            } while path.nonExisting == nil

            let _ = try path.createFile(containing: data, canOverwrite: false)
            return UploadIdentifier(id.uuidString)
        case .database:
            guard let connection = connection else {
                throw GenericSwiftlierError("deleting upload", because: "no database connection was provided")
            }
            var id: UUID
            var result: RowsResult<SelectQuery<UploadRecord>>
            repeat {
                id = UUID()
                let select = UploadRecord.select()
                    .filtered(UploadRecord.field(.id) == id.uuidString)
                    .limited(to: 1)
                result = try connection.execute(select)
            } while result.rows.next() != nil

            let record = UploadRecord(id: id.uuidString, content: data, created: Date())
            try connection.execute(try record.insert())
            return UploadIdentifier(id.uuidString)
        }
    }

    public static func deleteFile(for identifier: UploadIdentifier, storage: Storage = .fileSystem, connection: Connection?) throws {
        switch storage {
        case .fileSystem:
            try self.getPath(for: identifier)?.delete()
        case .database:
            guard let connection = connection else {
                throw GenericSwiftlierError("deleting upload", because: "no database connection was provided")
            }
            let delete = UploadRecord.delete()
                .filtered(UploadRecord.field(.id) == identifier.string)
            try connection.execute(delete)
        }
    }

    public static func response(to request: Request, for identifier: String, storage: Storage = .fileSystem) throws -> ResponseStatus {
        switch storage {
        case .fileSystem:
            guard let path = try self.getPath(for: UploadIdentifier(identifier)) else {
                return .unhandled
            }
            return .handled(try request.response(withFileAt: path.url, status: .ok))
        case .database:
            let select = UploadRecord.select()
                .filtered(UploadRecord.field(.id) == identifier)
                .limited(to: 1)
            let result = try request.databaseConnection.execute(select)
            guard let row = result.rows.next() else {
                return .unhandled
            }
            let upload: UploadRecord = try row.decode(purpose: .create)
            return .handled(request.response(body: upload.content, status: .ok))
        }
    }

    @available(*, deprecated)
    public static func path(for identifier: UploadIdentifier) throws -> FilePath? {
        return try self.getPath(for: identifier)
    }
}

private extension UploadService {
    static func directory() throws -> DirectoryPath {
        return try FileSystem.default.workingDirectory.subdirectory("Uploads")
    }

    static func getPath(for identifier: UploadIdentifier) throws -> FilePath? {
        return try self.directory().file(identifier.string).file
    }
}
