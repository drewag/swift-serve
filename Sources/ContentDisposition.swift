//
//  ContentDisposition.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 1/27/18.
//

import Foundation

public enum ContentDisposition {
    case inline
    case attachment(fileName: String?)

    case none
    case other(String)

    public init(_ string: String?) {
        guard let string = string, !string.isEmpty else {
            self = .none
            return
        }

        var parts = string.components(separatedBy: ";")

        switch parts.removeFirst().trimmingWhitespaceOnEnds.lowercased() {
        case "inline":
            self = .inline
        case "attachment" where parts.count > 0:
            let remaining = parts.joined(separator: ";")
            guard let fileName = StructuredHeader.parse(remaining)["filename"] else {
                self = .attachment(fileName: nil)
                return
            }
            self = .attachment(fileName: fileName)
        case "attachment":
            self = .attachment(fileName: nil)
        default:
            self = .other(string)
        }
    }
}
