import Swiftlier
import Foundation
import Decree

public protocol Response: CustomStringConvertible {
    var status: HTTPStatus {get}
    var error: SwiftlierError? {get}
    var headers: [String:String] {get set}
}

public enum Redirect {
    case permanently,temporarily,completedPost
}

extension Request {
    public func response(withData data: Data, status: HTTPStatus, error: SwiftlierError? = nil) -> Response {
        return self.response(withData: data, status: status, error: error, headers: [:])
    }

    public func response(withFileAt path: String, status: HTTPStatus, error: SwiftlierError? = nil) throws -> Response {
        return try self.response(withFileAt: path, status: status, error: error, headers: [:])
    }

    public func response(withData data: Data, status: HTTPStatus, headers: [String:String]) -> Response {
        return self.response(withData: data, status: status, error: nil, headers: headers)
    }

    public func response(withFileAt path: String, status: HTTPStatus, headers: [String:String]) throws -> Response {
        return try self.response(withFileAt: path, status: status, error: nil, headers: headers)
    }

    public func response(withFileAt url: URL, status: HTTPStatus, error: SwiftlierError? = nil, headers: [String:String] = [:]) throws -> Response {
        return try self.response(withFileAt: url.relativePath, status: status, error: error, headers: headers)
    }

    public func response(status: HTTPStatus = .ok, error: SwiftlierError? = nil, headers: [String:String] = [:]) -> Response {
        return self.response(withData: Data(), status: status, error: error, headers: headers)
    }

    public func response(body: Data, status: HTTPStatus = .ok, error: SwiftlierError? = nil, headers: [String:String] = [:]) -> Response {
        return self.response(withData: body, status: status, error: error, headers: headers)
    }

    public func response(body: String, status: HTTPStatus = .ok, error: SwiftlierError? = nil, headers: [String:String] = [:]) -> Response {
        let data = body.data(using: .utf8) ?? Data()
        return self.response(withData: data, status: status, error: error, headers: headers)
    }

    public func response<E: Encodable>(json: E, purpose: CodingPurpose = .create, userInfo: [CodingUserInfoKey:Any] = [:], status: HTTPStatus = .ok, error: SwiftlierError? = nil, headers: [String:String] = [:]) throws -> Response {
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

    public func response(jsonFromNativeTypes object: Any, status: HTTPStatus = .ok, error: SwiftlierError? = nil, headers: [String:String] = [:]) throws -> Response {
        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        return self.response(
            withData: data,
            status: status,
            error: error,
            headers: headers
        )
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

