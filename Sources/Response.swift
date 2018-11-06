import Swiftlier
import Foundation
import Stencil

public protocol Response: CustomStringConvertible {
    var status: HTTPStatus {get}
    var headers: [String:String] {get set}
}

extension Request {
    public func response(withData data: Data, status: HTTPStatus) -> Response {
        return self.response(withData: data, status: status, headers: [:])
    }

    public func response(withFileAt path: String, status: HTTPStatus) throws -> Response {
        return try self.response(withFileAt: path, status: status, headers: [:])
    }

    public func response(withFileAt url: URL, status: HTTPStatus) throws -> Response {
        return try self.response(withFileAt: url.relativePath, status: status, headers: [:])
    }

    public func response(status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        return self.response(withData: Data(), status: status, headers: headers)
    }

    public func response(body: Data, status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        return self.response(withData: body, status: status, headers: headers)
    }

    public func response(body: String, status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        let data = body.data(using: .utf8) ?? Data()
        return self.response(withData: data, status: status, headers: headers)
    }

    public func response<E: Encodable>(json: E, purpose: CodingPurpose = .create, userInfo: [CodingUserInfoKey:Any] = [:], status: HTTPStatus = .ok, headers: [String:String] = [:]) throws -> Response {
        let encoder = JSONEncoder()
        encoder.userInfo = userInfo
        encoder.userInfo.set(purposeDefault: purpose)
        encoder.userInfo.set(locationDefault: .remote)
        encoder.dateEncodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
        return self.response(
            withData: try encoder.encode(json),
            status: status,
            headers: headers
        )
    }

    public func response(redirectingTo to: String, permanently: Bool) -> Response {
        return self.response(status: permanently ? .movedPermanently : .temporaryRedirect, headers: ["Location": "\(to)"])
    }

    public func response(jsonFromNativeTypes object: Any, status: HTTPStatus = .ok, headers: [String:String] = [:]) throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return self.response(
            withData: data,
            status: status,
            headers: headers
        )
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
        return self.status.description
    }
}
