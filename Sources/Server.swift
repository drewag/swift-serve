//
//  Server.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

import Foundation

public protocol Server {
    var extraLogForRequest: ((Request) -> String?)? {get set}

    init(host: String, port: Int, router: Router) throws
    init(host: String, port: Int, router: Router, certificatePath: String, privateKeyPath: String) throws

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

        var json = "{"
        switch error {
        case let error as ReportableResponseError:
            json += "\"message\":\"\(escape(error.description))\""
        default:
            json += "\"message\":\"\(escape(error.localizedDescription))\""
        }
        if let error = error as? ReportableResponseError {
            json += ",\"identifier\":\"\(escape(error.identifier ?? "other"))\""
            for (field, value) in error.otherInfo ?? [:] {
                json += ",\"\(escape(field))\":\"\(escape(value))\""
            }
        }
        json += "}"
        return request.response(body: json, status: (error as? ReportableResponseError)?.status ?? .internalServerError)
    }
}
