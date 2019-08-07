//
//  SwiftServeError.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/2/19.
//

import Foundation
import Swiftlier
import Decree

public struct SwiftServeError: SwiftlierError {
    public enum Code {
        case status(HTTPStatus, underlyingError: SwiftlierError)
        case redirect(Redirect, destination: String, headers: [String:String])
    }

    public let code: Code

    public var title: String {
        switch self.code {
        case .status(_, let underlyingError):
            return underlyingError.title
        case .redirect(let type, _, _):
            switch type {
            case .temporarily:
                return "Temporary Redirect"
            case .permanently:
                return "Permanent Redirect"
            case .completedPost:
                return "Redirect"
            }
        }
    }

    public var alertMessage: String {
        switch self.code {
        case .status(_, let underlyingError):
            return underlyingError.alertMessage
        case .redirect(_, let destination, _):
            return "Destination: \(destination)"
        }
    }

    public var details: String? {
        switch self.code {
        case .status(let status, let underlyingError):
            if let details = underlyingError.details {
                return """
                    Status: \(status.description)
                    \(details)
                    """
            }
            else {
                return "Status: \(status.description)"
            }
        case .redirect(_, _, let headers):
            return "Headers:\n" + headers.map({ key, value in
                return "\(key): \(value)"
            }).joined(separator: "\n")
        }
    }

    public var isInternal: Bool {
        switch self.code {
        case .redirect:
            return true
        case .status(_, let underlyingError):
            return underlyingError.isInternal
        }
    }

    let _backtrace: [String]?

    public var backtrace: [String]? {
        switch self.code {
        case .redirect:
            return _backtrace
        case .status(_, let underlyingError):
            return underlyingError.backtrace ?? self._backtrace
        }
    }

    public var description: String {
        switch self.code {
        case .status(_, let underlyingError):
            return underlyingError.description
        case .redirect:
            return "\(self.title): \(self.alertMessage)"
        }
    }

    public init(_ code: Code, backtrace: [String]? = Thread.callStackSymbols) {
        self.code = code
        self._backtrace = backtrace
    }

    public init(_ status: HTTPStatus, _ doing: String, reason: String, details: String? = nil, byUser: Bool = false, backtrace: [String]? = Thread.callStackSymbols) {
        let error = GenericSwiftlierError(title: "Error \(doing)", alertMessage: reason, details: details, isInternal: !byUser, backtrace: backtrace)
        self.code = .status(status, underlyingError: error)
        self._backtrace = backtrace
    }
}

extension SwiftServeError: DecreeErrorDescribable {
    public var reason: String {
        return self.alertMessage
    }
}
