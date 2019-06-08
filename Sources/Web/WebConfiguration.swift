//
//  WebConfiguration.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 12/2/18.
//

public struct WebConfiguration {
    public typealias PreProcessHandler = (_ request: Request, _ context: inout [String : Any]) throws -> ()

    public let viewSubdirectory: String
    public let preprocess: PreProcessHandler?

    var viewRoot: String {
        var path = "Views/"
        if !self.viewSubdirectory.isEmpty {
            path += self.viewSubdirectory + "/"
        }
        return path
    }

    var cssRoot: String {
        var path = "Assets/css/"
        if !self.viewSubdirectory.isEmpty {
            path += self.viewSubdirectory.lowercased() + "/"
        }
        return path
    }

    var generatedWorkingRoot: String {
        var root = "Generated-working/"
        if !self.viewSubdirectory.isEmpty {
            root += self.viewSubdirectory + "/"
        }
        return root
    }

    public init(viewSubdirectory: String, preprocess: PreProcessHandler? = nil) {
        self.viewSubdirectory = viewSubdirectory
        self.preprocess = preprocess
    }
}
