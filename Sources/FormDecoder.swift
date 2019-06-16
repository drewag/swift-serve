//
//  FormDecoder
//  SwiftServe
//
//  Created by Andrew J Wagner on 6/9/19.
//

import Foundation
import Swiftlier

class FormDecoder: Decoder, ErrorGenerating {
    struct SimpleError: LocalizedError {
        let description: String

        var errorDescription: String? {
            return description
        }
    }

    let values: FormValues
    let codingPath: [CodingKey]
    var userInfo: [CodingUserInfoKey : Any] = [:]

    init(values: FormValues, codingPath: [CodingKey] = []) {
        self.values = values
        self.codingPath = codingPath
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        return KeyedDecodingContainer(KeyedFormDecodingContainer<Key>(decoder: self))
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let values = self.values.array
        return UnkeyedFormDecodingContainer(decoder: self, values: values, codingPath: self.codingPath)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return SingleValueFormDecodingContainer(decoder: self, codingPath: self.codingPath)
    }

    static func error(_ description: String) -> Error {
        return SimpleError(description: description)
    }
}

struct SingleValueFormDecodingContainer: SingleValueDecodingContainer {
    let decoder: FormDecoder
    let codingPath: [CodingKey]

    init(decoder: FormDecoder, codingPath: [CodingKey]) {
        self.decoder = decoder
        self.codingPath = codingPath
    }

    func decodeNil() -> Bool {
        return !self.decoder.values.hasValue
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        let string = try self.decode(String.self).lowercased()
        return string == "yes" || string == "on"
    }

    func decode(_ type: String.Type) throws -> String {
        return self.decoder.values.string ?? ""
    }

    func decode(_ type: Double.Type) throws -> Double {
        let string = try self.decode(String.self)
        guard let value = Double(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a decimal number.")
        }
        return value
    }

    func decode(_ type: Float.Type) throws -> Float {
        let string = try self.decode(String.self)
        guard let value = Float(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a decimal number.")
        }
        return value
    }

    func decode(_ type: Int.Type) throws -> Int {
        let string = try self.decode(String.self)
        guard let value = Int(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        let string = try self.decode(String.self)
        guard let value = Int8(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        let string = try self.decode(String.self)
        guard let value = Int16(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        let string = try self.decode(String.self)
        guard let value = Int32(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        let string = try self.decode(String.self)
        guard let value = Int64(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        let string = try self.decode(String.self)
        guard let value = UInt(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        let string = try self.decode(String.self)
        guard let value = UInt8(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        let string = try self.decode(String.self)
        guard let value = UInt16(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        let string = try self.decode(String.self)
        guard let value = UInt32(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        let string = try self.decode(String.self)
        guard let value = UInt64(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard type != String.self else {
            return try self.decode(String.self) as! T
        }

        guard type != Date.self else {
            guard let date = try self.decode(String.self).iso8601DateTime else {
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "invalid date")
            }
            return date as! T
        }

        guard type != EmailAddress.self else {
            let string = try self.decode(String.self)
            guard let email = try? EmailAddress(string: string) else {
                throw FormDecoder.error("'\(string)' is not a valid email")
            }
            return email as! T
        }

        let subValues = self.decoder.values
        let decoder = FormDecoder(values: subValues, codingPath: self.codingPath)
        decoder.userInfo = self.decoder.userInfo
        let result = try T(from: decoder)
        return result
    }
}

struct UnkeyedFormDecodingContainer: UnkeyedDecodingContainer {
    let decoder: FormDecoder
    let values: [FormValues]
    let codingPath: [CodingKey]
    var currentIndex: Int = 0

    init(decoder: FormDecoder, values: [FormValues], codingPath: [CodingKey]) {
        self.decoder = decoder
        self.values = values
        self.codingPath = codingPath
    }

    var count: Int? {
        return self.values.count
    }
    var isAtEnd: Bool {
        return currentIndex >= self.values.count
    }

    func decodeNil() throws -> Bool {
        return !self.values[currentIndex].hasValue
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        let string = try self.string().lowercased()
        let result = string == "yes" && string == "on"
        currentIndex += 1
        return result
    }

    mutating func decode(_ type: String.Type) throws -> String {
        let string = try self.string()
        currentIndex += 1
        return string
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        let string = try self.string()
        guard let value = Double(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an decimal number.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        let string = try self.string()
        guard let value = Float(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an decimal number.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        let string = try self.string()
        guard let value = Int(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        let string = try self.string()
        guard let value = Int8(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        let string = try self.string()
        guard let value = Int16(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        let string = try self.string()
        guard let value = Int32(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        let string = try self.string()
        guard let value = Int64(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        let string = try self.string()
        guard let value = UInt(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an positive integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        let string = try self.string()
        guard let value = UInt8(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an positive integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        let string = try self.string()
        guard let value = UInt16(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an positive integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        let string = try self.string()
        guard let value = UInt32(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an positive integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        let string = try self.string()
        guard let value = UInt64(string) else {
            throw FormDecoder.error("'\(string)' is invalid. It must be an positive integer.")
        }
        currentIndex += 1
        return value
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        guard type != String.self else {
            return try self.decode(String.self) as! T
        }

        guard type != Date.self else {
            guard let date = try self.decode(String.self).iso8601DateTime else {
                currentIndex -= 1
                throw DecodingError.dataCorruptedError(in: self, debugDescription: "invalid date")
            }
            return date as! T
        }

        guard type != EmailAddress.self else {
            let string = try self.string()
            guard let email = try? EmailAddress(string: string) else {
                throw FormDecoder.error("'\(string)' is not a valid email")
            }
            return email as! T
        }

        let subValues = self.subValues()
        let decoder = FormDecoder(values: subValues, codingPath: self.codingPath)
        decoder.userInfo = self.decoder.userInfo
        let result = try T(from: decoder)
        currentIndex += 1
        return result
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let decoder = FormDecoder(values: self.subValues())
        decoder.userInfo = self.decoder.userInfo
        return KeyedDecodingContainer(KeyedFormDecodingContainer(decoder: decoder))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        let values = self.subValues().array
        return UnkeyedFormDecodingContainer(decoder: self.decoder, values: values, codingPath: self.codingPath)
    }

    mutating func superDecoder() throws -> Decoder {
        return self.decoder
    }
}

class KeyedFormDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    let decoder: FormDecoder

    init(decoder: FormDecoder) {
        self.decoder = decoder
    }

    var values: FormValues {
        return self.decoder.values
    }

    var codingPath: [CodingKey] {
        return self.decoder.codingPath
    }

    var allKeys: [Key] {
        return self.values.keys.compactMap({ string in
            return Key(stringValue: string)
        })
    }

    func contains(_ key: Key) -> Bool {
        return self.values[key.stringValue]?.hasValue ?? false
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard let string = self.values[key.stringValue]?.string else {
            return true
        }
        return string.isEmpty
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        let string = self.values[key.stringValue]?.string?.lowercased()
        return string == "yes" || string == "on"
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        let string = try self.string(for: key)
        guard let value = Int(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        let string = try self.string(for: key)
        guard let value = Int8(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        let string = try self.string(for: key)
        guard let value = Int16(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        let string = try self.string(for: key)
        guard let value = Int32(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        let string = try self.string(for: key)
        guard let value = Int64(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be an integer.")
        }
        return value
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        let string = try self.string(for: key)
        guard let value = UInt(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        let string = try self.string(for: key)
        guard let value = UInt8(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        let string = try self.string(for: key)
        guard let value = UInt16(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        let string = try self.string(for: key)
        guard let value = UInt32(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        let string = try self.string(for: key)
        guard let value = UInt64(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a positive integer.")
        }
        return value
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        let string = try self.string(for: key)
        guard let value = Float(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a decimal number.")
        }
        return value
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        let string = try self.string(for: key)
        guard let value = Double(string) else {
            throw FormDecoder.error("\(key.stringValue) is invalid. It must be a decimal number.")
        }
        return value
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        return try self.string(for: key)
    }

    func decode(_ type: Data.Type, forKey key: Key) throws -> Data {
        throw self.decoder.error("decoding", because: "data not supported by form decoder")
    }

    func decode<D>(_ type: D.Type, forKey key: Key) throws -> D where D: Swift.Decodable {
        guard type != String.self else {
            return try self.decode(String.self, forKey: key) as! D
        }

        guard type != Date.self else {
            guard let date = try self.decode(String.self, forKey: key).iso8601DateTime else {
                throw DecodingError.dataCorruptedError(forKey: key, in: self, debugDescription: "invalid date")
            }
            return date as! D
        }

        guard type != EmailAddress.self else {
            let string = try self.string(for: key)
            guard let email = try? EmailAddress(string: string) else {
                throw FormDecoder.error("'\(string)' is not a valid email")
            }
            return email as! D
        }

        let subValues = try self.subValues(for: key)
        let decoder = FormDecoder(values: subValues, codingPath: self.codingPath + [key])
        decoder.userInfo = self.decoder.userInfo
        return try D(from: decoder)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "decoding nested containers is not supported"))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "decoding unkeyed containers is not supported"))
    }

    func superDecoder() throws -> Swift.Decoder {
        return self.decoder
    }

    func superDecoder(forKey key: Key) throws -> Swift.Decoder {
        throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "decoding super decoders is not supported"))
    }
}

private extension UnkeyedFormDecodingContainer {
    func subValues() -> FormValues {
        return self.values[self.currentIndex]
    }

    func string() throws -> String {
        guard let string = self.subValues().string, !string.isEmpty else {
            throw DecodingError.dataCorruptedError(in: self, debugDescription: "object found instead of string")
        }
        return string
    }
}

private extension KeyedFormDecodingContainer {
    func subValues(for key: Key) throws -> FormValues {
        guard let values = self.values[key.stringValue] else {
            throw DecodingError.keyNotFound(key, .init(codingPath: self.decoder.codingPath, debugDescription: "key not found"))
        }
        return values

    }

    func string(for key: Key) throws -> String {
        guard let string = try self.subValues(for: key).string, !string.isEmpty else {
            throw DecodingError.keyNotFound(key, .init(codingPath: self.decoder.codingPath, debugDescription: "key not found"))
        }
        return string
    }
}

