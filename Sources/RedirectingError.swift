//
//  RedirectingError.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 6/16/19.
//

import Foundation

public struct RedirectingError: Error, LocalizedError, CustomStringConvertible {
    let destination: String
    let headers: [String:String]

    public init(destination: String, headers: [String:String]) {
        self.destination = destination
        self.headers = headers
    }

    public var description: String {
        return "Redirect to '\(destination)'"
    }

    public var errorDescription: String? {
        return self.description
    }
}

