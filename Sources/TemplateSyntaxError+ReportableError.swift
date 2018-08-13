//
//  TemplateSyntaxError+ReportableError.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/3/18.
//

import Stencil
import Swiftlier

extension TemplateSyntaxError: ReportableErrorConvertible, ErrorGenerating {
    public var reportableError: ReportableError {
        return self.error("displaying", because: self.description)
    }
}
