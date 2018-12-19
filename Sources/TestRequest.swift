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
        cookies: [String:String] = [:]
        )
    {
        self.databaseConnection = connection
        self.method = method
        self.endpoint = endpoint
        self.data = data
        self.headers = headers

        var cookies = cookies
        for (key, value) in headers {
            guard key.lowercased() == "cookie" else {
                continue
            }

            guard let range = value.range(of: "=") else {
                continue
            }
            let cookieKey = value[value.startIndex ..< range.lowerBound]
            let cookiesValue = value[range.upperBound ..< value.endIndex]
            cookies[String(cookieKey)] = String(cookiesValue)
        }
        self.cookies = cookies
    }

    public func response(withData data: Data, status: HTTPStatus, error: ReportableError?, headers: [String:String]) -> Response {
        return TestDataResponse(status: status, data: data, error: error, headers: headers)
    }

    public func response(withFileAt path: String, status: HTTPStatus, error: ReportableError?, headers: [String:String]) throws -> Response {
        return TestFileResponse(status: status, filePath: path, error: error, headers: headers)
    }
}

public class TestDataResponse: Response {
    public let status: HTTPStatus
    public let data: Data
    public let error: ReportableError?
    public var headers: [String:String] = [:]

    public var json: JSON? {
        return try? JSON(data: data)
    }

    init(status: HTTPStatus, data: Data, error: ReportableError?, headers: [String:String]) {
        self.status = status
        self.data = data
        self.headers = headers
        self.error = error
    }
}

public class TestFileResponse: Response {
    public let status: HTTPStatus
    public let filePath: String
    public let error: ReportableError?
    public var headers: [String:String]

    init(status: HTTPStatus, filePath: String, error: ReportableError?, headers: [String:String]) {
        self.status = status
        self.filePath = filePath
        self.headers = headers
        self.error = error
    }
}
