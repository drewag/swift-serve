//
//  Server.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Foundation
import SwiftPlusPlus

public protocol Server: ErrorGenerating {
    var extraLogForRequest: ((Request) -> String?)? {get set}

    init(port: Int, router: Router) throws
    init(port: Int, router: Router, certificatePath: String, privateKeyPath: String) throws

    func start() throws
}

extension Server {
    public func log(response: Response, to request: Request) {
        if let extraLog = self.extraLogForRequest?(request) {
            Logger.main.log("\(request) \(extraLog) -> \(response)")
        }
        else {
            Logger.main.log("\(request) -> \(response)")
        }
    }

    public func unhandledResponse(to request: Request) -> Response {
        return request.response(body: "Path was: \(request.endpoint.absoluteString)", status: .notFound)
    }

    public func response(for error: Error, from request: Request) -> Response {
        func escape(_ string: String) -> String {
            return string.replacingOccurrences(of: "\"", with: "\\\"")
        }

        let reportableError = self.error("handling request", from: error)

        let status: HTTPStatus
        switch reportableError {
        case let networkError as NetworkRequestError:
            status = networkError.status
        default:
            switch reportableError.perpetrator {
            case .system, .temporaryEnvironment:
                status = .internalServerError
            case .user:
                status = .badRequest
            }
        }

        return request.response(json: reportableError, mode: .update, status: status)
    }
}
