//
//  FormEncoder.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 6/9/19.
//

import Foundation
import Swiftlier

class FormEncoder: Encoder {
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any] = [:]
    var values = FormValues()

    init(codingPath: [CodingKey] = []) {
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedFormEncodingContainer<Key>(encoder: self))
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedFormEncodingContainer(encoder: self)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return SingleValueFormEncodingContainer(encoder: self, codingPath: self.codingPath)
    }
}

struct SingleValueFormEncodingContainer: SingleValueEncodingContainer {
    let codingPath: [CodingKey]
    let encoder: FormEncoder

    init(encoder: FormEncoder, codingPath: [CodingKey]) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    mutating func encodeNil() throws {
        try self.encode("")
    }

    mutating func encode(_ value: Bool) throws {
        try self.encode(value ? "Yes" : "No")
    }

    mutating func encode(_ value: String) throws {
        self.encoder.values.string = value
    }

    mutating func encode(_ value: Double) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Float) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int8) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int16) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int32) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int64) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt8) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt16) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt32) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt64) throws {
        try self.encode("\(value)")
    }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if let date = value as? Date {
            try self.encode(date.iso8601DateTime)
        }
        else if let string = value as? String {
            try self.encode(string)
        }
        else if let email = value as? EmailAddress {
            try self.encode(email.string)
        }
        else {
            let encoder = FormEncoder(codingPath: self.codingPath)
            encoder.userInfo = self.encoder.userInfo
            try value.encode(to: encoder)
            self.encoder.values.string = encoder.values.string
        }
    }
}

struct UnkeyedFormEncodingContainer: UnkeyedEncodingContainer {
    let encoder: FormEncoder
    let codingPath: [CodingKey]
    var count: Int {
        return self.encoder.values.array.count
    }

    init(encoder: FormEncoder, codingPath: [CodingKey] = []) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    mutating func encodeNil() throws {
        try self.encode("")
    }

    mutating func encode(_ value: String) throws {
        self.encoder.values.array.append(FormValues(string: value))
    }

    mutating func encode(_ value: Bool) throws {
        try self.encode(value ? "Yes" : "No")
    }

    mutating func encode(_ value: Double) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Float) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int8) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int16) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int32) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: Int64) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt8) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt16) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt32) throws {
        try self.encode("\(value)")
    }

    mutating func encode(_ value: UInt64) throws {
        try self.encode("\(value)")
    }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        if let date = value as? Date {
            try self.encode(date.iso8601DateTime)
        }
        else if let string = value as? String {
            try self.encode(string)
        }
        else if let email = value as? EmailAddress {
            try self.encode(email.string)
        }
        else {
            let encoder = FormEncoder(codingPath: self.codingPath)
            encoder.userInfo = self.encoder.userInfo
            try value.encode(to: encoder)
            self.encoder.values.array.append(encoder.values)
        }
    }

    mutating func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        return KeyedEncodingContainer(KeyedFormEncodingContainer(encoder: self.encoder, codingPath: self.codingPath))
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedFormEncodingContainer(encoder: self.encoder, codingPath: self.codingPath)
    }

    mutating func superEncoder() -> Encoder {
        return self.encoder
    }

}

class KeyedFormEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
    let encoder: FormEncoder
    let codingPath: [CodingKey]

    init(encoder: FormEncoder, codingPath: [CodingKey] = []) {
        self.encoder = encoder
        self.codingPath = codingPath
    }

    func encodeNil(forKey key: Key) throws {
        try self.encode("", forKey: key)
    }

    func encode(_ value: Bool, forKey key: Key) throws {
        try self.encode(value ? "Yes" : "No", forKey: key)
    }

    func encode(_ value: String, forKey key: Key) throws {
        self.encoder.values.dictionary[key.stringValue] = FormValues(string: value)
    }

    func encode(_ value: Double, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: Float, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: Int, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: Int8, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: Int16, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: Int32, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: Int64, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: UInt, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: UInt8, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: UInt16, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: UInt32, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode(_ value: UInt64, forKey key: Key) throws {
        try self.encode("\(value)", forKey: key)
    }

    func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        if let date = value as? Date {
            try self.encode(date.iso8601DateTime, forKey: key)
        }
        else if let string = value as? String {
            try self.encode(string, forKey: key)
        }
        else if let email = value as? EmailAddress {
            try self.encode(email.string, forKey: key)
        }
        else {
            let encoder = FormEncoder(codingPath: [key])
            encoder.userInfo = self.encoder.userInfo
            try value.encode(to: encoder)
            self.encoder.values.dictionary[key.stringValue] = encoder.values
        }
    }

    func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        fatalError("encoding a nested container is not supported")
    }

    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        fatalError("encoding a nested container is not supported")
    }

    func superEncoder() -> Encoder {
        return self.encoder
    }

    func superEncoder(forKey key: Key) -> Encoder {
        return self.encoder
    }
}
