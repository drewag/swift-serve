//
//  Path+Stencil.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/24/18.
//

import Swiftlier

extension Path {
    public func rendered(build: (inout [String:Any]) -> ()) throws -> String {
        return try String(renderedFromTemplate: self.url.relativePath, build: build)
    }
}
