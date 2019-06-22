import Swiftlier
import Foundation
import Stencil

public protocol Response: CustomStringConvertible {
    var status: HTTPStatus {get}
    var error: ReportableError? {get}
    var headers: [String:String] {get set}
}

public enum Redirect {
    case permanently,temporarily,completedPost
}

extension Request {
    public func response(withData data: Data, status: HTTPStatus, error: ReportableError? = nil) -> Response {
        return self.response(withData: data, status: status, error: error, headers: [:])
    }

    public func response(withFileAt path: String, status: HTTPStatus, error: ReportableError? = nil) throws -> Response {
        return try self.response(withFileAt: path, status: status, error: error, headers: [:])
    }

    public func response(withData data: Data, status: HTTPStatus, headers: [String:String]) -> Response {
        return self.response(withData: data, status: status, error: nil, headers: headers)
    }

    public func response(withFileAt path: String, status: HTTPStatus, headers: [String:String]) throws -> Response {
        return try self.response(withFileAt: path, status: status, error: nil, headers: headers)
    }

    public func response(withFileAt url: URL, status: HTTPStatus, error: ReportableError? = nil, headers: [String:String] = [:]) throws -> Response {
        return try self.response(withFileAt: url.relativePath, status: status, error: error, headers: headers)
    }

    public func response(status: HTTPStatus = .ok, error: ReportableError? = nil, headers: [String:String] = [:]) -> Response {
        return self.response(withData: Data(), status: status, error: error, headers: headers)
    }

    public func response(body: Data, status: HTTPStatus = .ok, error: ReportableError? = nil, headers: [String:String] = [:]) -> Response {
        return self.response(withData: body, status: status, error: error, headers: headers)
    }

    public func response(body: String, status: HTTPStatus = .ok, error: ReportableError? = nil, headers: [String:String] = [:]) -> Response {
        let data = body.data(using: .utf8) ?? Data()
        return self.response(withData: data, status: status, error: error, headers: headers)
    }

    public func response<E: Encodable>(json: E, purpose: CodingPurpose = .create, userInfo: [CodingUserInfoKey:Any] = [:], status: HTTPStatus = .ok, error: ReportableError? = nil, headers: [String:String] = [:]) throws -> Response {
        let encoder = JSONEncoder()
        encoder.userInfo = userInfo
        encoder.userInfo.set(purposeDefault: purpose)
        encoder.userInfo.set(locationDefault: .remote)
        encoder.dateEncodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
        return self.response(
            withData: try encoder.encode(json),
            status: status,
            error: error,
            headers: headers
        )
    }

    @available (*, deprecated)
    public func response(redirectingTo to: String, permanently: Bool) -> Response {
        return self.response(redirectingTo: to, permanently ? .permanently : .temporarily)
    }

    public func response(redirectingTo to: String, _ redirect: Redirect, headers: [String:String] = [:]) -> Response {
        let status: HTTPStatus
        switch redirect {
        case .temporarily:

            status = .temporaryRedirect
        case .permanently:
            status = .movedPermanently
        case .completedPost:
            status = .seeOther
        }
        var headers = headers
        headers["Location"] = to
        return self.response(status: status, headers: headers)
    }

    public func response(jsonFromNativeTypes object: Any, status: HTTPStatus = .ok, error: ReportableError? = nil, headers: [String:String] = [:]) throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return self.response(
            withData: data,
            status: status,
            error: error,
            headers: headers
        )
    }

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
        let environment = Environment(loader: FileSystemLoader(paths: ["./"]))
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
        let environment = Environment(loader: FileSystemLoader(paths: ["./"]))
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


    public func response(template name: String, contentType: String =  "text/html; charset=utf-8", status: HTTPStatus = .ok, headers: [String:String] = [:], build: ((inout [String:Any]) -> ())? = nil) throws -> Response {
        let environment = Environment(loader: FileSystemLoader(paths: ["./"]))
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

extension Response  {
    public var description: String {
        if let error = self.error {
            return "\(self.status.description)\n\(error)"
        }
        else {
            return self.status.description
        }
    }
}
