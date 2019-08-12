//
//  Response+Form.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/2/19.
//

import Foundation
import Decree
import Stencil

extension Request {
    public func responseCreating<Value: Decodable>(
        type: Value.Type,
        template name: String,
        contentType: String =  "text/html; charset=utf-8",
        status: HTTPStatus = .ok,
        headers: [String:String] = [:],
        buildBeforeParse: ((inout [String:Any]) throws -> ())? = nil,
        build: ((Value?, inout [String:Any]) throws -> Response?)? = nil
        ) throws -> Response
    {
        let environment = Environment.html
        var context = [String:Any]()
        try self.preprocessStack.process(request: self, context: &context)
        do {
            try buildBeforeParse?(&context)
            let value: Value? = try self.decodableFromForm()
            if let response = try build?(value, &context) {
                return response
            }
        }
        catch {
            for (key, value) in self.formValues() {
                let key = key.replacingOccurrences(of: "[", with: "_")
                    .replacingOccurrences(of: "]", with: "_")
                context[key] = context[key] ?? value
            }
            context["error"] = error.localizedDescription
        }
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

    public func responseEditing<Value: Codable>(
        _ input: Value,
        template name: String,
        contentType: String =  "text/html; charset=utf-8",
        status: HTTPStatus = .ok,
        headers: [String:String] = [:],
        buildBeforeParse: ((inout [String:Any]) throws -> ())? = nil,
        build: ((Value?, inout [String:Any]) throws -> Response?)? = nil
        ) throws -> Response
    {
        let environment = Environment.html

        var context = [String:Any]()
        try self.preprocessStack.process(request: self, context: &context)
        switch self.method {
        case .post:
            do {
                try buildBeforeParse?(&context)
                let value: Value? = try self.decodableFromForm()
                if let response = try build?(value, &context) {
                    return response
                }
                if let value = value {
                    try context.writeFormData(for: value)
                }
            }
            catch {
                for (key, value) in self.formValues() {
                    let key = key.replacingOccurrences(of: "[", with: "_")
                        .replacingOccurrences(of: "]", with: "_")
                    context[key] = context[key] ?? value
                }
                context["error"] = error.localizedDescription
            }
        default:
            do {
                try buildBeforeParse?(&context)
                try context.writeFormData(for: input)
                if let response = try build?(nil, &context) {
                    return response
                }
            }
            catch {
                context["error"] = error.localizedDescription
            }
        }
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
