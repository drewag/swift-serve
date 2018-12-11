//
//  Form.swift
//  web
//
//  Created by Andrew J Wagner on 11/27/16.
//
//

import Swiftlier
import Stencil

public protocol HTMLFormField: RawRepresentable, Hashable, CaseIterable {
    static var action: String {get}
}

public class HTMLForm<Field: HTMLFormField>: ErrorGenerating where Field.RawValue == String {
    fileprivate var fields: [Field:String]
    fileprivate var error: String? = nil
    fileprivate var response: ResponseStatus? = nil
    public var message: String? = nil

    init(fields: [Field:String]) {
        self.fields = fields
    }

    public func value(for field: Field) -> String? {
        return self.fields[field]
    }

    public func requiredValue(for field: Field) throws -> String {
        guard let value = self.value(for: field) else {
            throw self.error("parsing form", because: "\(self.display(for: field)) is required")
        }
        return value
    }

    public func clear(field: Field) {
        self.fields[field] = nil
    }

    func display(for field: Field) -> String {
        var output = ""
        for character in field.rawValue {
            guard !output.isEmpty else {
                output.append(character)
                output = output.uppercased()
                continue
            }

            if character >= "A" && character <= "Z" {
                output += " \(character)".uppercased()
            }
            else {
                output.append(character)
            }
        }
        return output
    }
}

extension Request {
    public func parseForm<Field>(defaultValues: [Field:String?] = [:], process: (HTMLForm<Field>) throws -> (ResponseStatus?)) -> HTMLForm<Field> {
        guard Field.allCases.count > 0 else {
            return HTMLForm(fields: [:])
        }

        var parsedFields = [Field:String]()
        let formValues = self.formValues()
        for field in Field.allCases {
            parsedFields[field] = formValues[field.rawValue]
                ?? defaultValues[field]
                ?? ""
        }

        let form = HTMLForm(fields: parsedFields)

        switch self.method {
        case .post:
            do {
                try form.executeWhileRephrasingErrors(as: Field.action) {
                    try form.executeWhileReattributingErrors(to: .user) {
                        form.response = try process(form)
                    }
                }
            }
            catch let error {
                form.error = "\(error)"
            }
        case .get:
            break
        default:
            form.response = .unhandled
        }

        return form
    }

    public func responseStatus<Field>(template name: String, status: HTTPStatus = .ok, headers: [String:String] = [:], form: HTMLForm<Field>, build: ((inout [String:Any]) -> ())? = nil) throws -> ResponseStatus {
        if let response = form.response {
            return response
        }
        return .handled(try self.response(template: name, status: status, headers: headers, build: { context in
            for (key, value) in form.fields {
                context[key.rawValue] = value
            }
            context["error"] = form.error
            context["message"] = form.message
            build?(&context)
        }))
    }
}
