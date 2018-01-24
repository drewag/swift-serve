//
//  Client.swift
//  OnBeatCore
//
//  Created by Andrew J Wagner on 11/26/16.
//
//

import Foundation
import Swiftlier

public protocol ClientRequest {
    init(method: HTTPMethod, url: URL, headers: [String:String], username: String?, password: String?, body: Data)
}

public protocol ClientResponse {
    var body: Data {get}
    var status: HTTPStatus {get}
}

public protocol Client {
    init(url: URL) throws
    func respond(to: ClientRequest) -> ClientResponse
}

public class ClientFactory {
    public static let singleton = ClientFactory()

    public var clientType: Client.Type!
    public var requestType: ClientRequest.Type!

    public func createClient(for url: URL) throws -> Client {
        return try self.clientType.init(url: url)
    }

    public func createRequest(
        withMethod method: HTTPMethod,
        url: URL,
        headers: [String:String] = [:],
        username: String? = nil,
        password: String? = nil,
        body: String
        ) -> ClientRequest
    {
        return self.requestType.init(
            method: method,
            url: url,
            headers: headers,
            username: username,
            password: password,
            body: body.data(using: .utf8) ?? Data()
        )
    }

    public func createRequest(
        withMethod method: HTTPMethod,
        url: URL,
        headers: [String:String] = [:],
        username: String? = nil,
        password: String? = nil,
        body: Data
        ) -> ClientRequest
    {
        return self.requestType.init(
            method: method,
            url: url,
            headers: headers,
            username: username,
            password: password,
            body: body
        )
    }
}

extension ClientResponse {
    public var text: String? {
        return String(data: self.body, encoding: .utf8)
    }

    public var json: JSON? {
        return try? JSON(data: self.body)
    }
}
