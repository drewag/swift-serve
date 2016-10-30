//
//  TestServer.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Foundation
import SwiftServe

struct TestRequest: Request {
    let method: HTTPMethod
    let endpoint: URL
    let data: Data

    func response(withData data: Data, status: HTTPStatus) -> Response {
        return TestResponse(data: data, status: status)
    }
}

struct TestResponse: Response {
    let data: Data
    let status: HTTPStatus
}

struct TestServer: Server {
    let router: Router

    init(port: Int, router: Router) {
        self.router = router
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
}

extension Response {
    var string: String? {
        return String(data: (self as! TestResponse).data, encoding: .utf8)
    }
}
