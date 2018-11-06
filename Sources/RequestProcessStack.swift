//
//  RequestProcessStack.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 11/2/18.
//

import Foundation

public struct RequestProcessStack {
    public typealias Process = (Request, inout [String:Any]) throws -> ()
    private var stack: [Process] = []

    public init() {}

    public mutating func append(_ process: @escaping Process) {
        self.stack.append(process)
    }

    public mutating func append(_ process: [Process]) {
        self.stack += process
    }

    public mutating func pop(count: Int = 1) {
        for _ in 0 ..< count {
            let _ = self.stack.popLast()
        }
    }

    public func process(request: Request, context: inout [String:Any]) throws {
        for process in self.stack {
            try process(request, &context)
        }
    }
}
