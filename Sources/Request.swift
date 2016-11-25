import Foundation
import SwiftPlusPlus

public protocol Request: CustomStringConvertible {
    var method: HTTPMethod {get}
    var endpoint: URL {get}
    var data: Data {get}
    var headers: [String:String] {get}
    var cookies: [String:String] {get}
    var host: String {get}

    func response(withData data: Data, status: HTTPStatus, headers: [String:String]) -> Response
    func response(withFileAt path: String, status: HTTPStatus, headers: [String:String]) throws -> Response
}

extension Request {
    public var string: String? {
        return String(data: self.data, encoding: .utf8)
    }

    public func encodableFromJson<Encodable: EncodableType>() throws -> Encodable? {
        let object = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions())
        return NativeTypesDecoder.decodableTypeFromObject(object)
    }

    public func encodableFromJsonArray<Encodable: EncodableType>() throws -> [Encodable]? {
        guard let objectArray = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions()) as? [Any] else {
            return nil
        }

        var array = [Encodable]()

        for object in objectArray {
            if let decodable: Encodable = NativeTypesDecoder.decodableTypeFromObject(object) {
                array.append(decodable)
            }
        }
        
        return array
    }

    public func encodableFromJsonDict<Encodable: EncodableType>() throws -> [String:Encodable]? {
        guard let objectDict = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions()) as? [String:Any] else {
            return nil
        }

        var dict = [String:Encodable]()

        for (key, object) in objectDict {
            dict[key] = NativeTypesDecoder.decodableTypeFromObject(object)
        }

        return dict
    }

    public var json: JSON? {
        return try? JSON(data: self.data)
    }
}

extension Request {
    public var description: String {
        let now = Date().dateAndTime
        return "\(now) \(self.method)\t\(self.endpoint.absoluteString)"
    }
}
