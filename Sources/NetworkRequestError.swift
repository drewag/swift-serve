//
//  NetworkRequestErrorReason.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 4/15/17.
//
//

import SwiftPlusPlus

final class NetworkRequestError: ReportableError {
    let status: HTTPStatus
    let doing: String
    let because: String
    let source: ErrorGenerating.Type

    fileprivate init(_ doing: String, withStatus status: HTTPStatus, because: String, from: ErrorGenerating.Type) {
        self.doing = doing
        self.status = status
        self.because = because
        self.source = from
    }

    var perpetrator: ErrorPerpitrator {
        switch self.status.rawValue {
        case 200 ..< 300:
            return .system
        case 300 ..< 500:
            return .user
        default:
            return .system
        }
    }

    var reason: AnyErrorReason {
        return ErrorReason(self.because)
    }
}

extension Request {
    public func networkError(_ doing: String, withStatus status: HTTPStatus, because: String) -> ReportableError {
        return NetworkRequestError(doing, withStatus: status, because: because, from: type(of: self))
    }
}

extension NetworkRequestError {
    struct Keys {
        class status: CoderKey<Int> {}
    }

    func encode(_ encoder: Encoder) {
        self.encodeStandard(encoder)
        encoder.encode(self.status.rawValue, forKey: Keys.status.self)
    }
}
