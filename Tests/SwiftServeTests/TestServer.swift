//
//  TestServer.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Foundation
import Swiftlier
import SQL
import PostgreSQL

@testable import SwiftServe

struct TestRequest: Request {
    let databaseConnection: Connection = PostgreSQLConnection()
    let method: HTTPMethod
    let endpoint: URL
    let data: Data
    let headers: [String:String] = [:]
    let cookies: [String:String] = [:]
    let host: String = ""
    let ip: String = ""

    init(method: HTTPMethod, endpoint: URL, data: Data) {
        self.method = method
        self.endpoint = endpoint
        self.data = data
    }

    var preprocessStack = RequestProcessStack()
    var postprocessStack = RequestProcessStack()

    func response(withData data: Data, status: HTTPStatus, error: ReportableError?, headers: [String:String]) -> Response {
        return TestResponse(data: data, status: status, headers: headers, error: error)
    }

    func response(withFileAt path: String, status: HTTPStatus, error: ReportableError?, headers: [String:String]) throws -> Response {
        let url = URL(fileURLWithPath: path)
        let path = FileSystem.default.path(from: url)
        let data = try path.file?.contents() ?? Data()
        return TestResponse(data: data, status: status, headers: headers, error: error)
    }
}

struct TestResponse: Response {
    let data: Data
    let status: HTTPStatus
    var headers: [String : String]
    var error: ReportableError?
}

struct TestServer: Server {
    var errorViewRoot: String
    var extraLogForRequest: ((Request) -> String?)?

    var postProcessResponse: ((inout Response) -> ())?

    let router: Router

    init(port: Int, router: Router, errorViewRoot: String) {
        self.router = router
        self.errorViewRoot = errorViewRoot
    }

    init(port: Int, router: Router, errorViewRoot: String, certificatePath: String, privateKeyPath: String) {
        self.router = router
        self.errorViewRoot = errorViewRoot
    }

    func route(string: String, at url: URL, as method: HTTPMethod) throws -> Response {
        let path = url.relativePath
        let data: Data
        if string.isEmpty {
            data = Data()
        }
        else {
            data = string.data(using: .utf8)!
        }

        let request = TestRequest(method: method, endpoint: url, data: data)
        switch try self.router.route(request: request, to: path) {
        case .handled(let response):
            return response
        case .unhandled:
            return request.response(status: .notFound)
        }
    }

    func start() throws {
    }
}

extension Response {
    var string: String? {
        return String(data: (self as! TestResponse).data, encoding: .utf8)
    }
}
