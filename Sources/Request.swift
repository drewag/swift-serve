import Foundation
import SwiftPlusPlus

public protocol Request: CustomStringConvertible {
    var databaseConnection: DatabaseConnection {get}
    var method: HTTPMethod {get}
    var endpoint: URL {get}
    var data: Data {get}
    var headers: [String:String] {get}
    var cookies: [String:String] {get}
    var host: String {get}
    var ip: String {get}

    func response(withData data: Data, status: HTTPStatus, headers: [String:String]) -> Response
    func response(withFileAt path: String, status: HTTPStatus, headers: [String:String]) throws -> Response
}

extension Request {
    public var string: String? {
        return String(data: self.data, encoding: .utf8)
    }

    public var baseURL: URL {
        guard let host = self.headers["Host"] else {
            return URL(string: "/", relativeTo: self.endpoint)!.absoluteURL
        }
        return URL(string: "https://\(host)", relativeTo: nil)
            ?? URL(string: "/", relativeTo: self.endpoint)!.absoluteURL
    }

    public func decodableFromJson<Decodable: DecodableType>() throws -> Decodable? {
        let object = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions())
        return try? NativeTypesDecoder.decodableTypeFromObject(object, mode: .remote)
    }

    public func decodableFromJsonArray<Decodable: DecodableType>() throws -> [Decodable]? {
        guard let objectArray = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions()) as? [Any] else {
            return nil
        }

        var array = [Decodable]()

        for object in objectArray {
            if let decodable: Decodable = try? NativeTypesDecoder.decodableTypeFromObject(object, mode: .remote) {
                array.append(decodable)
            }
        }
        
        return array
    }

    public func decodableFromJsonDict<Decodable: DecodableType>() throws -> [String:Decodable]? {
        guard let objectDict = try JSONSerialization.jsonObject(with: self.data, options: JSONSerialization.ReadingOptions()) as? [String:Any] else {
            return nil
        }

        var dict = [String:Decodable]()

        for (key, object) in objectDict {
            dict[key] = try? NativeTypesDecoder.decodableTypeFromObject(object, mode: .remote)
        }

        return dict
    }

    public var json: JSON? {
        return try? JSON(data: self.data)
    }

    public func formValues() -> [String:String] {
        var output = [String:String]()

        var urlComponents = self.endpoint.absoluteString.components(separatedBy: "?")
        if urlComponents.count > 1 {
            urlComponents.removeFirst()
            let query = urlComponents.joined()
            for variable in query.components(separatedBy: "&") {
                var components = variable.components(separatedBy: "=")
                if components.count > 1 {
                    let key = components.removeFirst()
                    output[key.removingPercentEncoding ?? key] = components.joined().removingPercentEncoding
                }
            }
        }

        if let string = self.string {
            for pair in string.components(separatedBy: "&") {
                let components = pair.components(separatedBy: "=")
                guard components.count == 2 else {
                    continue
                }

                func unencode(_ string: String) -> String? {
                    let withSpaces = string.replacingOccurrences(of: "+", with: " ")
                    return withSpaces.removingPercentEncoding
                }
                guard let key = unencode(components[0]) else {
                    continue
                }
                guard let value = unencode(components[1]) else {
                    continue
                }
                output[key] = value
            }
        }

        return output
    }

    public func createCookie(withName name: String, value: String, maxAge: TimeInterval) -> String {
        let key = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let value = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let date = Date(timeIntervalSinceNow: maxAge)
        return "\(key)=\(value); Expires=\(date.gmtDateTime)"
    }
}

extension Request {
    public var description: String {
        let now = Date().dateAndTime
        return "\(now) \(self.method)\t\(self.endpoint.absoluteString)"
    }
}
