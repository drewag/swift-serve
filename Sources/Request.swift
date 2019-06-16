import Foundation
import Swiftlier
import SQL

public protocol Request: CustomStringConvertible, ErrorGenerating {
    var databaseConnection: Connection {get}
    var method: HTTPMethod {get}
    var endpoint: URL {get}
    var data: Data {get}
    var headers: [String:String] {get}
    var cookies: [String:String] {get}
    var host: String {get}
    var ip: String {get}

    var preprocessStack: RequestProcessStack {get set}
    var postprocessStack: RequestProcessStack {get set}

    func response(withData data: Data, status: HTTPStatus, error: ReportableError?, headers: [String:String]) -> Response
    func response(withFileAt path: String, status: HTTPStatus, error: ReportableError?, headers: [String:String]) throws -> Response
}

extension Request {
    public var string: String? {
        return String(data: self.data, encoding: .utf8)
    }

    public var baseURL: URL {
        return URL(string: "/", relativeTo: self.endpoint)!.absoluteURL
    }

    public var contentType: ContentType {
        return ContentType(self.headers["Content-Type"])
    }

    public var contentTransferEncoding: ContentTransferEncoding {
        return ContentTransferEncoding(self.headers["Content-Transfer-Encoding"])
    }

    public var contentDisposition: ContentDisposition {
        return ContentDisposition(self.headers["Content-Dispoition"])
    }

    var accepts: [ContentType] {
        return ContentType.types(from: self.headers["Accept"])
    }

    public func accepts(_ contentType: ContentType) -> Bool {
        return self.accepts.contains(where: {$0 == contentType})
    }

    public func decodableFromJSON<Value: Decodable>(source: CodingLocation = .local, purpose: CodingPurpose = .create, userInfo: [CodingUserInfoKey:Any] = [:]) throws -> Value? {
        let decoder = JSONDecoder()
        decoder.userInfo = userInfo
        decoder.userInfo.set(purposeDefault: purpose)
        decoder.userInfo.set(locationDefault: source)
        decoder.dateDecodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
        return try? decoder.decode(Value.self, from: self.data)
    }

    public func decodableFromForm<Value: Decodable>(source: CodingLocation = .local, purpose: CodingPurpose = .create, userInfo: [CodingUserInfoKey:Any] = [:]) throws -> Value? {
        switch self.method {
        case .post:
            do {
                let value: Value = try self.values().decodable(source: source, purpose: purpose, userInfo: userInfo)
                return value
            }
            catch let error as DecodingError {
                switch error {
                case .keyNotFound(let key, _):
                    throw FormDecoder.error("\(key.stringValue) is required")
                default:
                    throw error
                }
            }
            catch {
                throw error
            }
        default:
            return nil
        }
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

        switch self.contentType {
        case .multipartFormData:
            if let part = self.mimePart {
                switch part.content {
                case .multipartFormData(let parts):
                    for part in parts {
                        if let name = part.name, let plain = part.plain {
                            output[name] = plain
                        }
                    }
                default:
                    break
                }
            }
        default:
            if let string = self.string {
                output.append(string, parsedWith: FormUrlEncoded.self)
            }
        }

        return output
    }

    public func values() -> FormValues {
        var values = FormValues()

        var urlComponents = self.endpoint.absoluteString.components(separatedBy: "?")
        if urlComponents.count > 1 {
            urlComponents.removeFirst()
            let query = urlComponents.joined()
            for variable in query.components(separatedBy: "&") {
                var components = variable.components(separatedBy: "=")
                if components.count > 1 {
                    let key = components.removeFirst()
                    values.add(
                        key: key.removingPercentEncoding ?? key,
                        value: components.joined().removingPercentEncoding ?? components.joined()
                    )
                }
            }
        }

        switch self.contentType {
        case .multipartFormData:
            if let part = self.mimePart {
                switch part.content {
                case .multipartFormData(let parts):
                    for part in parts {
                        if let name = part.name, let plain = part.plain {
                            values.add(key: name, value: plain)
                        }
                    }
                default:
                    break
                }
            }
        default:
            if let string = self.string {
                for (key, value) in FormUrlEncoded.values(from: string) {
                    values.add(key: key, value: value)
                }
            }
        }


        return values
    }

    public func createCookie(withName name: String, value: String, maxAge: TimeInterval, path: String? = nil) -> String {
        let key = name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let value = value.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let date = Date(timeIntervalSinceNow: maxAge)
        var cookie = "\(key)=\(value); Expires=\(date.gmtDateTime)"
        if let path = path {
            cookie += "; Path=\(path)"
        }
        return cookie
    }

    public var mimePart: MimePart? {
        return try? MimePart(
            body: self.data,
            headers: self.headers,
            contentType: self.contentType,
            contentTransferEncoding: self.contentTransferEncoding,
            contentDisposition: self.contentDisposition
        )
    }
}

extension Request {
    public var description: String {
        let now = Date().dateAndTime
        return "\(now) \(self.method)\t\(self.endpoint.absoluteString)"
    }
}
