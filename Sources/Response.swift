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


    public func response(status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        return self.response(withData: Data(), status: status, headers: headers)
    }

    public func response(body: String, status: HTTPStatus = .ok, headers: [String:String] = [:]) -> Response {
        let data = body.data(using: .utf8) ?? Data()
        return self.response(withData: data, status: status, headers: headers)
    }

    public func response(json: EncodableType, status: HTTPStatus = .ok, headers: [String:String] = [:]) throws -> Response {
        let object = NativeTypesEncoder.objectFromEncodable(json)
        let data = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions())
        return self.response(withData: data, status: status, headers: headers)
    }

    public func response(json: [EncodableType], status: HTTPStatus = .ok, headers: [String:String] = [:]) throws -> Response {
        var objectArray = [Any]()

        for value in json {
            objectArray.append(NativeTypesEncoder.objectFromEncodable(value))
        }

        let data = try JSONSerialization.data(withJSONObject: objectArray, options: JSONSerialization.WritingOptions())
        return self.response(withData: data, status: status, headers: headers)
    }

    public func response(json: [String:EncodableType], status: HTTPStatus = .ok, headers: [String:String] = [:]) throws -> Response {
        var objectDict = [String:Any]()

        for (key, value) in json {
            objectDict[key] = NativeTypesEncoder.objectFromEncodable(value)
        }

        let data = try JSONSerialization.data(withJSONObject: objectDict, options: JSONSerialization.WritingOptions())
        return self.response(withData: data, status: status, headers: headers)
    }
}

extension Response  {
    public var description: String {
        return self.status.description
    }
}
