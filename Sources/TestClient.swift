//
//  TestClientRequest.swift
//  web
//
//  Created by Andrew J Wagner on 1/17/18.
//

import Foundation
import Swiftlier
import SQL

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
    public static var routerToHandleRequest: ((TestClientRequest) -> ((Router, Connection)?))?

    public required init(url: URL) throws {
    }

    public func respond(to request: ClientRequest) -> ClientResponse {
        if let request = request as? TestClientRequest {
            type(of: self).executedRequests.append(request)
        }
        guard let block = type(of: self).onRequest else {
            if let request = request as? TestClientRequest {
                if let (router, connection) = type(of: self).routerToHandleRequest?(request) {
                    let request = TestRequest(connection: connection, method: request.method, endpoint: request.url, data: request.body, headers: request.headers)
                    do {
                        let responseStatus = try router.route(request: request, to: request.endpoint.relativePath)
                        switch responseStatus {
                        case .handled(let response):
                            return TestClientResponse(body: (response as? TestDataResponse)?.data ?? Data(), status: response.status)
                        case .unhandled:
                            return TestClientResponse(body: Data(), status: .notFound)
                        }
                    }
                    catch let error as NetworkError {
                        let json = try? JSONEncoder().encode(error)
                        return TestClientResponse(body: json ?? Data(), status: error.status)
                    }
                    catch let error as ReportableError {
                        let json = try? JSONEncoder().encode(error)
                        return TestClientResponse(body: json ?? Data(), status: .internalServerError)
                    }
                    catch {
                        return TestClientResponse(body: Data(), status: .internalServerError)
                    }
                }
            }
            return TestClientResponse(body: Data(), status: .ok)
        }
        let result = block(request)
        return TestClientResponse(body: result.body, status: result.status)
    }
}

extension TestClientRequest {
    public func multiFormParts(usingBoundary boundary: String) -> [String:MimePart] {
        let parts = (try? MimePart.parts(in: self.body, usingBoundary: boundary, characterEncoding: .isoLatin1)) ?? []
        return parts.reduce(into: [:], { result, part in
            if let name = part.name {
                result[name] = part
            }
        })
    }
}
