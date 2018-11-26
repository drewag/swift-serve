//
//  StaticPagesGenerator.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/26/18.
//

import Foundation
import Swiftlier

class StaticPagesGenerator {
    static func removeDirectory(at path: String) {
        let _ = try? FileSystem.default.path(from: URL(fileURLWithPath: path)).directory?.delete()
    }

    static func createDirectory(at path: String) {
        let _ = try? FileSystem.default.path(from: URL(fileURLWithPath: path)).createDirectory()
    }

    static func write(_ html: String, to path: String) throws {
        let _  = try FileSystem.default.path(from: URL(fileURLWithPath: path)).createFile(containing: html.data(using: .utf8) ?? Data(), canOverwrite: true)
    }

    static func moveItem(from: String, to: String) throws {
        let from = FileSystem.default.path(from: URL(fileURLWithPath: from))
        let to = FileSystem.default.path(from: URL(fileURLWithPath: to))
        let _ = try from.existing?.move(to: to, canOverwrite: true)
    }

    static func copyFile(from: String, to: String) throws {
        let from = FileSystem.default.path(from: URL(fileURLWithPath: from))
        let to = FileSystem.default.path(from: URL(fileURLWithPath: to))
        let _ = try from.file?.copy(to: to, canOverwrite: true)
    }

    func removeDirectory(at path: String) {
        type(of: self).removeDirectory(at: path)
    }

    func createDirectory(at path: String) {
        type(of: self).createDirectory(at: path)
    }

    func write(_ html: String, to path: String) throws {
        try type(of: self).write(html, to: path)
    }

    func moveItem(from: String, to: String) throws {
        try type(of: self).moveItem(from: from, to: to)
    }

    func copyFile(from: String, to: String) throws {
        try type(of: self).copyFile(from: from, to: to)
    }

    func generate(forDomain domain: String) throws {}
}
