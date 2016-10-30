import Foundation
import SwiftPlusPlus

public protocol Request {
    var method: HTTPMethod {get}
    var endpoint: URL {get}
    var data: Data {get}

    func response(withData: Data, status: HTTPStatus) -> Response
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
}
