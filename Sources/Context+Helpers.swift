//
//  Context+Helpers.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 6/21/19.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    public mutating func writeFormData<Value: Encodable>(for value: Value) throws {
        let encoder = FormEncoder()
        try value.encode(to: encoder)
        for (key, value) in encoder.values.rawValues {
            let key = key.replacingOccurrences(of: "[", with: "_")
                .replacingOccurrences(of: "]", with: "_")
            self[key] = self[key] ?? value
        }
    }
}
