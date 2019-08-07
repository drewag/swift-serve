//
//  Server.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Foundation
import Swiftlier
import Decree

public protocol Server {
    var extraLogForRequest: ((Request) -> String?)? {get set}
    var postProcessResponse: ((inout Response) -> ())? {get set}
    var errorViewRoot: String {get}

    init(port: Int, router: Router, errorViewRoot: String) throws
    init(port: Int, router: Router, errorViewRoot: String, certificatePath: String, privateKeyPath: String) throws

    func start() throws
}

extension Server {
    public func log(response: Response, to request: Request) {
        if let extraLog = self.extraLogForRequest?(request) {
            print("\(request) \(extraLog) -> \(response)")
        }
        else {
            print("\(request) -> \(response)")
        }
    }

    public func unhandledResponse(to request: Request) -> Response {
        return request.response(body: "Path was: \(request.endpoint.absoluteString)", status: .notFound)
    } 

    public func response(for error: Error, from request: Request) -> Response {
        let swiftlierError = error.swiftlierError(while: "handling request")
        let status: HTTPStatus
        switch swiftlierError.error {
        case let error as SwiftServeError:
            switch error.code {
            case let .redirect(type, destination, headers):
                return request.response(redirectingTo: destination, type, headers: headers)
            case let .status(errorStatus, _):
                status = errorStatus
            }
        default:
            if swiftlierError.isInternal {
                status = .internalServerError
            }
            else {
                status = .badRequest
            }
        }

        if request.accepts(.html(.utf8)),
            let htmlResponse = (try? request.response(
                template: "\(self.errorViewRoot)Unhandled.html",
                status: status,
                build: { context in
                    context["title"] = swiftlierError.title
                    context["alertMessage"] = swiftlierError.alertMessage
                    context["details"] = swiftlierError.details
                    context["description"] = swiftlierError.description
                    context["backtrace"] = swiftlierError.backtrace
                }
            ))
        {
            return htmlResponse
        }
        else {
            do {
                return try request.response(json: GenericSwiftlierError(swiftlierError), status: status, error: swiftlierError)
            }
            catch {
                return request.response(body: swiftlierError.description, status: status, error: swiftlierError)
            }
        }
    }
}
