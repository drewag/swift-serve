import SwiftPlusPlus
import Foundation

public protocol Response: CustomStringConvertible {
    var status: HTTPStatus {get}
}

extension Request {
    public func response(status: HTTPStatus = .ok) -> Response {
        return self.response(withData: Data(), status: status)
    }

    public func response(body: String, status: HTTPStatus = .ok) -> Response {
        let data = body.data(using: .utf8) ?? Data()
        return self.response(withData: data, status: status)
    }

    public func response(json: EncodableType, status: HTTPStatus = .ok) throws -> Response {
        let object = NativeTypesEncoder.objectFromEncodable(json)
        let data = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions())
        return self.response(withData: data, status: status)
    }

    public func response(json: [EncodableType], status: HTTPStatus = .ok) throws -> Response {
        var objectArray = [Any]()

        for value in json {
            objectArray.append(NativeTypesEncoder.objectFromEncodable(value))
        }

        let data = try JSONSerialization.data(withJSONObject: objectArray, options: JSONSerialization.WritingOptions())
        return self.response(withData: data, status: status)
    }

    public func response(json: [String:EncodableType], status: HTTPStatus = .ok) throws -> Response {
        var objectDict = [String:Any]()

        for (key, value) in json {
            objectDict[key] = NativeTypesEncoder.objectFromEncodable(value)
        }

        let data = try JSONSerialization.data(withJSONObject: objectDict, options: JSONSerialization.WritingOptions())
        return self.response(withData: data, status: status)
    }
}

extension Response  {
    public var description: String {
        return self.status.description
    }
}
