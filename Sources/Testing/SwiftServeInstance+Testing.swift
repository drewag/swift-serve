//
//  SwiftServeInstance+Testing.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/5/19.
//

import Foundation
import SQL
import PostgreSQL
import Decree
import Swiftlier

extension TestURLSession: Decree.Session {}

extension SwiftServeInstance {
    public var allRequestsHandler: WebService.AllRequestsHandler {
        return { request in
            do {
                try self.loadDatabaseSetup()
                let connection = PostgreSQLConnection(
                    host: "localhost",
                    databaseName: DatabaseSetup!.name,
                    username: DatabaseSetup!.username,
                    password: DatabaseSetup!.password
                )
                let method = Decree.Method(rawValue: request.httpMethod!)
                let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
                var headers = [CaseInsensitiveKey:String]()
                var cookies = [String:String]()
                for (key, value) in request.allHTTPHeaderFields ?? [:] {
                    guard key.lowercased() != "cookie" else {
                        for variable in value.components(separatedBy: "; ") {
                            var components = variable.components(separatedBy: "=")
                            if components.count > 1 {
                                let key = components.removeFirst()
                                cookies[key] = components.joined(separator: "=")
                            }
                        }
                        continue
                    }
                    headers[key] = value
                }
                let testRequest = TestRequest(
                    databaseConnection: connection,
                    method: method,
                    endpoint: request.url!,
                    data: request.httpBody ?? Data(),
                    headers: headers,
                    cookies: cookies,
                    host: components.host!,
                    ip: "0.0.0.0",
                    preprocessStack: .init(),
                    postprocessStack: .init()
                )

                let status = try self.route(request: testRequest, to: request.url!.relativePath)
                switch status {
                case .unhandled:
                    let response = HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)
                    return (nil, response, nil)
                case .handled(let response):
                    let response = response as! TestResponse
                    let urlResponse = HTTPURLResponse(url: request.url!, statusCode: response.status.rawValue, httpVersion: nil, headerFields: response.headers)
                    return (response.body, urlResponse, response.error)
                }
            }
            catch {
                return (nil, nil, error)
            }
        }
    }

    public func get(from endpoint: String, forAuth auth: (session: String, deviceId: String)? = nil, headers: [CaseInsensitiveKey:String]? = nil) throws -> TestResponse {
        return try self.response(method: .get, from: endpoint, data: Data(), headers: headers, forAuth: auth)
    }

    public func delete(from endpoint: String, forAuth auth: (session: String, deviceId: String)? = nil, headers: [CaseInsensitiveKey:String]? = nil) throws -> TestResponse {
        return try self.response(method: .delete, from: endpoint, data: Data(), headers: headers, forAuth: auth)
    }

    public func post(_ json: [String:Any]? = nil, to endpoint: String, forAuth auth: (session: String, deviceId: String)? = nil, headers: [CaseInsensitiveKey:String]? = nil) throws -> TestResponse {
        let data: Data
        if let json = json {
            data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        }
        else {
            data = Data()
        }
        return try self.response(method: .post, from: endpoint, data: data, headers: headers, forAuth: auth)
    }
}


private extension SwiftServeInstance {
    func response(method: Decree.Method, from endpoint: String, data: Data, headers: [CaseInsensitiveKey:String]?, forAuth auth: (session: String, deviceId: String)? = nil) throws -> TestResponse {
        let url = URL(string: "http://localhost:9999")!.appendingPathComponent(endpoint)
        var cookies = [String:String]()
        var headers = headers ?? [CaseInsensitiveKey:String]()
        if let auth = auth {
            cookies["session"] = auth.session
            headers["deviceId"] = auth.deviceId
        }

        try self.loadDatabaseSetup()
        let connection = PostgreSQLConnection(
            host: "localhost",
            databaseName: DatabaseSetup!.name,
            username: DatabaseSetup!.username,
            password: DatabaseSetup!.password
        )

        let testRequest = TestRequest(
            databaseConnection: connection,
            method: method,
            endpoint: url,
            data: data,
            headers: headers,
            cookies: cookies,
            host: "localhost",
            ip: "0.0.0.0",
            preprocessStack: .init(),
            postprocessStack: .init()
        )

        let status = try self.route(request: testRequest, to: endpoint)
        switch status {
        case .unhandled:
            throw GenericSwiftlierError("Making request", because: "It was not handled")
        case .handled(let response):
            return response as! TestResponse
        }
    }
}
