//
//  Server.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Foundation
import Swiftlier

public protocol Server: ErrorGenerating {
    var extraLogForRequest: ((Request) -> String?)? {get set}
    var postProcessResponse: ((inout Response) -> ())? {get set}

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
        let reportableError = self.error("handling request", from: error)

        let status: HTTPStatus
        switch reportableError {
        case let networkError as NetworkError:
            status = networkError.status
        default:
            switch reportableError.perpetrator {
            case .system, .temporaryEnvironment:
                status = .internalServerError
            case .user:
                status = .badRequest
            }
        }

        if request.accepts(.html(.utf8)),
            let htmlResponse = (try? request.response(
                template: "Views/Error.html",
                status: status,
                build: { context in
                    context["message"] = reportableError.description
                    context["doing"] = reportableError.doing
                    context["reason"] = reportableError.reason.because
                    context["alert_title"] = reportableError.alertDescription.title
                    context["alert_message"] = reportableError.alertDescription.message
                }
            ))
        {
            return htmlResponse
        }
        else {
            do {
                return try request.response(json: reportableError, status: status)
            }
            catch {
                return request.response(body: reportableError.description, status: status)
            }
        }
    }
}
