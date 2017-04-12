import SwiftPlusPlus
import Foundation
import TextTransformers

public protocol Response: CustomStringConvertible {
    var status: HTTPStatus {get}
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

    public func response(json: EncodableType, mode: EncodingMode, status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        return self.response(
            withData: JSON.encode(json, mode: mode),
            status: status,
            headers: headers
        )
    }

    public func response(redirectingTo to: String) -> Response {
        return self.response(status: .movedPermanently, headers: ["Location": "\(to)"])
    }

    public func response(json: [EncodableType], mode: EncodingMode, status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        return self.response(
            withData: JSON.encode(json, mode: mode),
            status: status,
            headers: headers
        )
    }

    public func response(json: [String:EncodableType], mode: EncodingMode, status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        return self.response(
            withData: JSON.encode(json, mode: mode),
            status: status,
            headers: headers
        )
    }

    public func response(jsonFromNativeTypes object: Any, status: HTTPStatus = .ok, headers: [String:String] = [:]) throws -> Response {
        return self.response(
            withData: try JSON.encode(object),
            status: status,
            headers: headers
        )
    }

    public func response(htmlFromFile fileUrl: URL, status: HTTPStatus = .ok, headers: [String:String] = [:], htmlBuild: (TemplateBuilder) -> ()) throws -> Response {
        return try self.response(htmlFromFiles: [fileUrl], headers: headers, htmlBuild: htmlBuild)
    }

    public func response(htmlFromFile filePath: String, status: HTTPStatus = .ok, headers: [String:String] = [:], htmlBuild: (TemplateBuilder) -> ()) throws -> Response {
        return try self.response(htmlFromFiles: [filePath], status: status, headers: headers, htmlBuild: htmlBuild)
    }

    public func response(htmlFromFiles fileUrls: [URL], status: HTTPStatus = .ok, headers: [String:String] = [:], htmlBuild: (TemplateBuilder) -> ()) throws -> Response {
        return try self.response(htmlFromFiles: fileUrls.map({$0.relativePath}), headers: headers, htmlBuild: htmlBuild)
    }

    public func response(htmlFromFiles filePaths: [String], status: HTTPStatus = .ok, headers: [String:String] = [:], htmlBuild: (TemplateBuilder) -> ()) throws -> Response {
        return try self.response(textFromFiles: filePaths, contentType: "text/html", status: status, headers: headers, textBuild: htmlBuild)
    }

    public func response(textFromFiles filePaths: [String], contentType: String, status: HTTPStatus = .ok, headers: [String:String] = [:], textBuild: (TemplateBuilder) -> ()) throws -> Response {
        let html = try filePaths.map(FileContents()).reduce(Separator()).map(Template(build: textBuild)).string()
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
