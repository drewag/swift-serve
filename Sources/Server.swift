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

    init(port: Int, router: Router) throws

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
        return request.response(body: "Path was: \(request.endpoint.absoluteString)")
    }

    public func response(for error: Error, from request: Request) -> Response {
        var json = "{"
        json += "\"message\":\"\(error)\""
        if let error = error as? ReportableResponseError {
            json += ",\"identifier\":\"\(error.identifier ?? "other")\""
            for (field, value) in error.otherInfo ?? [:] {
                json += ",\"\(field)\":\"\(value)\""
            }
        }
        json += "}"
        return request.response(body: json, status: (error as? ReportableResponseError)?.status ?? .internalServerError)
    }
}
