//
//  TestRequest.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/5/19.
//

import Foundation
import SQL
import Decree
import Swiftlier

public struct TestRequest: Request {
    public let databaseConnection: Connection
    public let method: Decree.Method
    public let endpoint: URL
    public let data: Data
    public let headers: [CaseInsensitiveKey:String]
    public let cookies: [String:String]
    public let host: String
    public let ip: String

    public var preprocessStack: RequestProcessStack
    public var postprocessStack: RequestProcessStack

    public func response(withData data: Data, status: HTTPStatus, error: SwiftlierError?, headers: [String:String]) -> Response {
        return TestResponse(body: data, status: status, error: error, headers: headers)
    }

    public func response(withFileAt path: String, status: HTTPStatus, error: SwiftlierError?, headers: [String:String]) throws -> Response {
        let url = URL(fileURLWithPath: path)
        let path = FileSystem.default.path(from: url)
        let data = try path.file?.contents() ?? Data()
        return TestResponse(body: data, status: status, error: error, headers: headers)
    }
}
