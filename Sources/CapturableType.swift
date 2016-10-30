//
//  CapturableType.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 10/29/16.
//
//

public protocol CapturableType {
    init?(fromCaptureText: String)
}

extension Int: CapturableType {
    public init?(fromCaptureText text: String) {
        self.init(text)
    }
}

extension Double: CapturableType {
    public init?(fromCaptureText text: String) {
        self.init(text)
    }
}

extension String: CapturableType {
    public init?(fromCaptureText text: String) {
        self.init(text)
    }
}
