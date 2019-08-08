//
//  HTTPHeader.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 8/7/19.
//

import Foundation

public struct CaseInsensitiveKey: Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public func hash(into hasher: inout Hasher) {
        let raw = self.rawValue.lowercased()
        raw.hash(into: &hasher)
    }

    public static func ==(lhs: CaseInsensitiveKey, rhs: CaseInsensitiveKey) -> Bool {
        return lhs.rawValue.lowercased() == rhs.rawValue.lowercased()
    }

    public static func ==(lhs: CaseInsensitiveKey, rhs: String) -> Bool {
        return lhs.rawValue.lowercased() == rhs.lowercased()
    }

    public static func ==(lhs: String, rhs: CaseInsensitiveKey) -> Bool {
        return rhs == lhs
    }
}

extension Dictionary where Key == CaseInsensitiveKey, Value == String {
    public subscript(key: String) -> String? {
        get {
            let key = CaseInsensitiveKey(rawValue: key)
            return self[key]
        }
        set {
            let key = CaseInsensitiveKey(rawValue: key)
            self[key] = newValue
        }
    }
}

extension CaseInsensitiveKey: CustomStringConvertible {
    public var description: String {
        return self.rawValue
    }
}
