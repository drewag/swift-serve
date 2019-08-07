//
//  Route+Endpoint.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/2/19.
//

import Foundation
import Decree
import Swiftlier

extension Route {
    public static func endpoint<E: EmptyEndpoint>(_ endpoint: E.Type, at path: String? = "", handler: @escaping (Request) throws -> HTTPStatus) -> Route {
        return self.route(method: E.method, path: path, handler: { request in
            let status = try handler(request)
            return .handled(request.response(status: status))
        })
    }

    public static func endpoint<E: InEndpoint>(_ endpoint: E.Type, at path: String? = "", decodingPurpose: CodingPurpose = .create, handler: @escaping (Request, E.Input) throws -> HTTPStatus) -> Route where E.Input: Decodable {
        return self.route(method: E.method, path: path, handler: { request in
            let decoder = JSONDecoder()
            decoder.userInfo.location = .remote
            decoder.userInfo.purpose = decodingPurpose
            decoder.dateDecodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
            let decoded: E.Input
            do {
                decoded = try decoder.decode(E.Input.self, from: request.data)
            }
            catch {
                throw error.swiftlierError(while: "parsing requests")
            }
            let status = try handler(request, decoded)
            return .handled(request.response(status: status))
        })
    }

    public static func endpoint<E: OutEndpoint>(_ endpoint: E.Type, at path: String? = "", encodingPurpose: CodingPurpose = .create, handler: @escaping (Request) throws -> (HTTPStatus, E.Output)) -> Route where E.Output: Encodable {
        return self.route(method: E.method, path: path, handler: { request in
            let (status, output) = try handler(request)
            return .handled(try request.response(json: output, purpose: encodingPurpose, status: status))
        })
    }

    public static func endpoint<E: InOutEndpoint>(_ endpoint: E.Type, at path: String? = "", decodingPurpose: CodingPurpose = .create, encodingPurpose: CodingPurpose = .create, handler: @escaping (Request, E.Input) throws -> (HTTPStatus, E.Output)) -> Route where E.Input: Decodable, E.Output: Encodable {
        return self.route(method: E.method, path: path, handler: { request in
            let decoder = JSONDecoder()
            decoder.userInfo.purpose = decodingPurpose
            decoder.userInfo.location = .remote
            decoder.dateDecodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
            let decoded: E.Input
            do {
                decoded = try decoder.decode(E.Input.self, from: request.data)
            }
            catch {
                throw error.swiftlierError(while: "parsing request")
            }
            let (status, output) = try handler(request, decoded)
            return .handled(try request.response(json: output, purpose: encodingPurpose, status: status))
        })
    }
}

extension ParameterizedRoute {
    public static func endpoint<E: EmptyEndpoint>(_ endpoint: E.Type, at path: String? = "", handler: @escaping (Request, Param) throws -> HTTPStatus) -> ParameterizedRoute<Param> {
        return self.route(method: E.method, path: path, handler: { request, param in
            let status = try handler(request, param)
            return .handled(request.response(status: status))
        })
    }

    public static func endpoint<E: InEndpoint>(_ endpoint: E.Type, at path: String? = "", decodingPurpose: CodingPurpose = .create, handler: @escaping (Request, Param, E.Input) throws -> HTTPStatus) -> ParameterizedRoute<Param> where E.Input: Decodable {
        return self.route(method: E.method, path: path, handler: { request, param in
            let decoder = JSONDecoder()
            decoder.userInfo.location = .remote
            decoder.userInfo.purpose = decodingPurpose
            decoder.dateDecodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
            let decoded: E.Input
            do {
                decoded = try decoder.decode(E.Input.self, from: request.data)
            }
            catch {
                throw error.swiftlierError(while: "parsing request")
            }
            let status = try handler(request, param, decoded)
            return .handled(request.response(status: status))
        })
    }

    public static func endpoint<E: OutEndpoint>(_ endpoint: E.Type, at path: String? = "", encodingPurpose: CodingPurpose = .create, handler: @escaping (Request, Param) throws -> (HTTPStatus, E.Output)) -> ParameterizedRoute<Param> where E.Output: Encodable {
        return self.route(method: E.method, path: path, handler: { request, param in
            let (status, output) = try handler(request, param)
            return .handled(try request.response(json: output, purpose: encodingPurpose, status: status))
        })
    }

    public static func endpoint<E: InOutEndpoint>(_ endpoint: E.Type, at path: String? = "", decodingPurpose: CodingPurpose = .create, encodingPurpose: CodingPurpose = .create, handler: @escaping (Request, Param, E.Input) throws -> (HTTPStatus, E.Output)) -> ParameterizedRoute<Param> where E.Input: Decodable, E.Output: Encodable {
        return self.route(method: E.method, path: path, handler: { request, param in
            let decoder = JSONDecoder()
            decoder.userInfo.location = .remote
            decoder.userInfo.purpose = decodingPurpose
            decoder.dateDecodingStrategy = .formatted(ISO8601DateTimeFormatters.first!)
            let decoded: E.Input
            do {
                decoded = try decoder.decode(E.Input.self, from: request.data)
            }
            catch {
                throw error.swiftlierError(while: "parsing requests")
            }
            let (status, output) = try handler(request, param, decoded)
            return .handled(try request.response(json: output, purpose: encodingPurpose, status: status))
        })
    }
}
