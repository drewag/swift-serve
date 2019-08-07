//
//  TestResponse.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/5/19.
//

import Foundation
import Decree
import Swiftlier

public struct TestResponse: Response {
    public let body: Data
    public let status: HTTPStatus
    public let error: SwiftlierError?
    public var headers: [String:String]

    public var json: JSON? {
        return try? JSON(data: self.body)
    }
}
