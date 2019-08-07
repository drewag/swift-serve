//
//  UploadService.swift
//  web
//
//  Created by Andrew J Wagner on 7/18/17.
//
//

import Foundation
import Swiftlier

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
    public let routes: [Route] = [
        .getWithParam(consumeEntireSubPath: false, handler: { (request, identifier: String) in
            guard let path = try UploadService.path(for: UploadIdentifier(identifier)) else {
                return .unhandled
            }
            return .handled(try request.response(withFileAt: path.url, status: .ok))
        })
    ]

    public init() {}

    private static func directory() throws -> DirectoryPath {
        return try FileSystem.default.workingDirectory.subdirectory("Uploads")
    }

    public static func saveFile(containing data: Data) throws -> UploadIdentifier {
        var id: UUID
        var path: Path
        repeat {
            id = UUID()
            path = try self.directory().file(id.uuidString)
        } while path.nonExisting == nil

        let _ = try path.createFile(containing: data, canOverwrite: false)
        return UploadIdentifier(id.uuidString)
    }

    public static func path(for identifier: UploadIdentifier) throws -> FilePath? {
        return try self.directory().file(identifier.string).file
    }
}

