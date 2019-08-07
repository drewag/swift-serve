//
//  String+Stencil.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/23/18.
//

import Stencil

extension String {
    public init(renderedFromTemplate template: String, build: (inout [String:Any]) -> ()) throws {
        let environment = Environment(loader: FileSystemLoader(paths: ["."]))
        var context = [String:Any]()
        build(&context)
        self = try environment.renderTemplate(name: template, context: context)
    }
}
