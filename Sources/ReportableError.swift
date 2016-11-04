//
//  ReportableError.swift
//  OnBeatCore
//
//  Created by Andrew J Wagner on 11/3/16.
//
//

import SwiftPlusPlus

public protocol ReportableResponseError: Error, CustomStringConvertible {
    var status: HTTPStatus { get }
    var identifier: String? { get }
    var otherInfo: [String:String]? { get }
}

public struct UserReportableError: ReportableResponseError {
    public let description: String
    public let status: HTTPStatus
    public let identifier: String? = nil
    public let otherInfo: [String:String]? =  nil

    public init(_ status: HTTPStatus, _ description: String) {
        self.status = status
        self.description = description
    }
}
