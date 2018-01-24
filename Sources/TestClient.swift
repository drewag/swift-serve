//
//  TestClientRequest.swift
//  web
//
//  Created by Andrew J Wagner on 1/17/18.
//

import Foundation
import Swiftlier

public struct TestClientRequest: ClientRequest {
    public let method: HTTPMethod
    public let url: URL
    public let headers: [String:String]
    public let username: String?
    public let password: String?
    public let body: Data

    public var bodyString: String? {
        return String(data: self.body, encoding: .utf8)
    }

    public init(
        method: HTTPMethod,
        url: URL,
        headers: [String : String],
        username: String?,
        password: String?,
        body: Data
        )
    {
        self.method = method
        self.url = url
        self.headers = headers
        self.username = username
        self.password = password
        self.body = body
    }
}

struct TestClientResponse: ClientResponse {
    let body: Data
    let status: HTTPStatus
}

public class TestClient: Client {
    public static var executedRequests = [TestClientRequest]()
    public static var onRequest: ((ClientRequest) -> (status: HTTPStatus, body: Data))?

    public required init(url: URL) throws {
    }

    public func respond(to request: ClientRequest) -> ClientResponse {
        if let request = request as? TestClientRequest {
            type(of: self).executedRequests.append(request)
        }
        guard let block = type(of: self).onRequest else {
            return TestClientResponse(body: Data(), status: .ok)
        }
        let result = block(request)
        return TestClientResponse(body: result.body, status: result.status)
    }
}

extension TestClientRequest {
    public func multiFormParts(usingBoundary boundary: String) -> [String:MultiFormPart] {
        let parts = MultiFormPart.parts(in: self.body, usingBoundary: boundary)
        var output = [String:MultiFormPart]()
        for part in parts {
            if let name = part.name {
                output[name] = part
            }
        }
        return output
    }
}
