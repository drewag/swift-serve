//
//  Server.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

public protocol Server {
    init(port: Int, router: Router)
}
