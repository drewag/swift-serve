//
//  NetworkRequestErrorReason.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 4/15/17.
//
//

import Foundation
import Swiftlier
import Decree

//extension Request {
//    public func networkError(_ doing: String, withStatus status: HTTPStatus, because: String) -> ReportableError {
//        let perpitrator: ErrorPerpitrator
//        switch status.rawValue {
//        case 200 ..< 300:
//            perpitrator = .system
//        case 300 ..< 500:
//            perpitrator = .user
//        default:
//            perpitrator = .system
//        }
//        return NetworkError(from: type(of: self), by: perpitrator, doing: doing, because: ErrorReason(because), status: status, backtrace: Thread.callStackSymbols)
//    }
//}
