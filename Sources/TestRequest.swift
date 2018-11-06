//
//  TestRequest.swift
//  SwiftServe
//
//  Created by Andrew Wagner on 12/21/17.
//

import Foundation
import SQL
import Swiftlier

public class TestRequest: Request {
    public let databaseConnection: Connection
    public let method: HTTPMethod
    public let endpoint: URL
    public let data: Data
    public let headers: [String:String]
    public let cookies: [String:String]
    public let host: String = "localhost"
    public let ip: String = "0.0.0.0"

    public var preprocessStack = RequestProcessStack()
    public var postprocessStack = RequestProcessStack()

    public init(
        connection: Connection,
        method: HTTPMethod,
        endpoint: URL,
        data: Data,
        headers: [String:String],
        cookies: [String:String]
        )
    {
        self.databaseConnection = connection
        self.method = method
        self.endpoint = endpoint
        self.data = data
        self.headers = headers
        self.cookies = cookies
    }

    public func response(withData data: Data, status: HTTPStatus, headers: [String:String]) -> Response {
        return TestDataResponse(status: status, data: data, headers: headers)
    }

    public func response(withFileAt path: String, status: HTTPStatus, headers: [String:String]) throws -> Response {
        return TestFileResponse(status: status, filePath: path, headers: headers)
    }
}

public class TestDataResponse: Response {
    public let status: HTTPStatus
    public let data: Data
    public var headers: [String:String] = [:]

    public var json: JSON? {
        return try? JSON(data: data)
    }

    init(status: HTTPStatus, data: Data, headers: [String:String]) {
        self.status = status
        self.data = data
        self.headers = headers
    }
}

public class TestFileResponse: Response {
    public let status: HTTPStatus
    public let filePath: String
    public var headers: [String:String]

    init(status: HTTPStatus, filePath: String, headers: [String:String]) {
        self.status = status
        self.filePath = filePath
        self.headers = headers
    }
}
