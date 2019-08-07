//
//  TemplateSyntaxError+SwiftlierError.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/3/18.
//

import Stencil
import Swiftlier

extension TemplateSyntaxError: SwiftlierError {
    public var title: String {
        return "Error Rendering"
    }

    public var alertMessage: String {
        return self.reason
    }

    public var details: String? {
        var details = ""

        if let templateName = self.templateName {
            details += "Template Name: \(templateName)"
        }

        if let token = self.token {
            if !details.isEmpty { details += "\n" }
            details += "Token: \(token.contents)"
        }

        if !self.stackTrace.isEmpty {
            if !details.isEmpty { details += "\n" }
            details += "Stack Trace: \(stackTrace.map({$0.contents}).joined(separator: " > "))"
        }

        return details
    }

    public var isInternal: Bool {
        return true
    }

    public var backtrace: [String]? {
        return nil
    }
}
