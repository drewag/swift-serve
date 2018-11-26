//
//  BlogConfiguration.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 11/25/18.
//

public struct BlogConfiguration {
    public let rootEndpoint: String
    public let notifyEmail: String
    public let notifyFromEmail: String

    public init(rootEndpoint: String, notifyEmail: String, notifyFromEmail: String) {
        self.rootEndpoint = rootEndpoint
        self.notifyEmail = notifyEmail
        self.notifyFromEmail = notifyFromEmail
    }
}
