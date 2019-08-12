//
//  Response+Template.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/2/19.
//

import Foundation
import Stencil
import Decree

extension Request {
    public func response(template name: String, contentType: String =  "text/html; charset=utf-8", status: HTTPStatus = .ok, headers: [String:String] = [:], build: ((inout [String:Any]) -> ())? = nil) throws -> Response {
        let environment = Environment.html
        var context = [String:Any]()
        try self.preprocessStack.process(request: self, context: &context)
        build?(&context)
        try self.postprocessStack.process(request: self, context: &context)
        let html = try environment.renderTemplate(name: name, context: context)
        var headers = headers
        if headers["Content-Type"] == nil {
            headers["Content-Type"] = contentType
        }
        if headers["Content-Disposition"] == nil {
            headers["Content-Disposition"] = "inline"
        }
        return self.response(body: html, status: status, headers: headers)
    }
}
