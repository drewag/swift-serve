//
//  Form.swift
//  web
//
//  Created by Andrew J Wagner on 11/27/16.
//
//

import TextTransformers

public protocol HTMLFormField: RawRepresentable, Hashable {
    static var all: [Self] {get}
}

public class HTMLForm<Field: HTMLFormField> where Field.RawValue == String {
    fileprivate let fields: [Field:String]
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
            throw UserReportableError(.badRequest, "\(self.display(for: field)) is required")
        }
        return value
    }

    func display(for field: Field) -> String {
        var output = ""
        for character in field.rawValue.characters {
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
    public func parseForm<Field: HTMLFormField>(process: (HTMLForm<Field>) throws -> (ResponseStatus?)) -> HTMLForm<Field> {
        guard Field.all.count > 0 else {
            return HTMLForm(fields: [:])
        }

        var parsedFields = [Field:String]()

        let formValues = self.formValues()
        for field in Field.all {
            parsedFields[field] = formValues[field.rawValue]
        }

        let form = HTMLForm(fields: parsedFields)

        switch self.method {
        case .post:
            do {
                form.response = try process(form)
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

    public func responseStatus<Field: HTMLFormField>(htmlFromFile filePath: String, status: HTTPStatus = .ok, headers: [String:String] = [:], form: HTMLForm<Field>, htmlBuild: ((TemplateBuilder) -> ())? = nil) throws -> ResponseStatus {
        return try self.responseStatus(htmlFromFiles: [filePath], status: status, headers: headers, form: form, htmlBuild: htmlBuild)
    }

    public func responseStatus<Field: HTMLFormField>(htmlFromFiles filePaths: [String], status: HTTPStatus = .ok, headers: [String:String] = [:], form: HTMLForm<Field>, htmlBuild: ((TemplateBuilder) -> ())? = nil) throws -> ResponseStatus {
        if let response = form.response {
            return response
        }
        return .handled(try self.response(htmlFromFiles: filePaths, status: status, headers: headers, htmlBuild: { builder in
            for (key, value) in form.fields {
                builder[key.rawValue] = value
            }
            builder["error"] = form.error
            builder["message"] = form.message
            htmlBuild?(builder)
        }))
    }
}
