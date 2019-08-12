//
//  StencilExtensions.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/9/19.
//

import Foundation
import Stencil

extension Environment {
    public init(emailWithParagaraphStyle paragraphStyle: String) {
        self .init(loader: FileSystemLoader(paths: ["./"]), extensions: [
            Environment.standardExtension,
            Environment.emailExtension(paragraphStyle: paragraphStyle),
        ])
    }

    public static var html: Environment {
        return Environment(loader: FileSystemLoader(paths: ["./"]), extensions: [
            self.standardExtension,
        ])
    }
}

private extension Environment {
    static var standardExtension: Extension {
        let ext = Extension()

        ext.registerFilter("plainToHtml", filter: { value in
            guard let string = value as? String else {
                return value
            }

            return string.replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: "\n", with: "<br/>")
        })

        ext.registerFilter("escapeHtml", filter: { value in
            guard let string = value as? String else {
                return value
            }

            return string.replacingOccurrences(of: "<", with: "&lt;")
        })

        return ext
    }

    static func emailExtension(paragraphStyle: String) -> Extension {
        let ext = Extension()

        ext.registerSimpleTag("p", handler: { context in
            return "<p style=\"\(paragraphStyle)\">"
        })

        return ext
    }
}
