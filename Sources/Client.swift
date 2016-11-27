//
//  Client.swift
//  OnBeatCore
//
//  Created by Andrew J Wagner on 11/26/16.
//
//

import Foundation

public protocol ClientRequest {
    init(method: HTTPMethod, url: URL, headers: [String:String], body: String)
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

    public func createRequest(withMethod method: HTTPMethod, url: URL, headers: [String:String], body: String) -> ClientRequest {
        return self.requestType.init(method: method, url: url, headers: headers, body: body)
    }
}
