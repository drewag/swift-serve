//
//  FormValues.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 6/8/19.
//

import Swiftlier

public struct FormValues: CustomStringConvertible {
    public var string: String?
    var dictionary: [String:FormValues]
    public var array: [FormValues]

    
    public init() {
        self.string = nil
        self.dictionary = [:]
        self.array = []
    }

    init(string: String? = nil, dictionary: [String:FormValues] = [:], array: [FormValues] = []) {
        self.string = string
        self.dictionary = dictionary
        self.array = array
    }

    public subscript(key: String) -> FormValues? {
        return self.dictionary[key]
    }

    public var hasValue: Bool {
        if let string = self.string, !string.isEmpty {
            return true
        }

        return !self.dictionary.isEmpty || !self.array.isEmpty
    }

    public var keys: [String] {
        return Array(self.dictionary.keys)
    }

    public var description: String {
        if dictionary.isEmpty {
            if array.isEmpty {
                if let string = string {
                    return #""\#(string)""#
                }
                else {
                    return "null"
                }
            }
            else {
                let arrayString = array.map({$0.description}).joined(separator: ",")
                if let string = string {
                    return #"<"\#(string)"|[\#(arrayString)]>"#
                }
                else {
                    return #"[\#(arrayString)]"#
                }
            }
        }
        else {
            let dictString = dictionary.map({ key, value in
                return #""\#(key)": \#(value)"#
            }).joined(separator: ",")
            if array.isEmpty {
                if let string = string {
                    return #"<"\#(string)"|[\#(dictString)]>"#
                }
                else {
                    return #"[\#(dictString)]"#
                }
            }
            else {
                let arrayString = array.map({$0.description}).joined(separator: ",")
                if let string = string {
                    return #"<"\#(string)"|[\#(arrayString)]|[\#(dictString)]>"#
                }
                else {
                    return #"<[\#(arrayString)]|[\#(dictString)]>"#
                }
            }
        }
    }

    public var rawValues: [(String, String)] {
        var output = [(String,String)]()

        for (key, value) in self.workingRawValues {
            let stringKey: String
            switch key.count {
            case 0:
                stringKey = ""
            case 1:
                stringKey = key[0]
            default:
                stringKey = key[0] + "[" + key[1...].joined(separator: "][") + "]"
            }
            output.append((stringKey,value))
        }

        return output
    }

    public func decodable<Value: Decodable>(source: CodingLocation = .local, purpose: CodingPurpose = .create, userInfo: [CodingUserInfoKey:Any] = [:]) throws -> Value {
        let decoder = FormDecoder(values: self)
        decoder.userInfo = userInfo
        decoder.userInfo.set(purposeDefault: purpose)
        decoder.userInfo.set(locationDefault: source)
        return try Value(from: decoder)
    }

    @discardableResult
    public mutating func add(key: String, value: String) -> Bool {
        let (nextComponent, remaining) = self.parse(key: key)
        if nextComponent.isEmpty {
            // Array Value
            if let remaining = remaining {
                if var last = self.array.last {
                    if last.add(key: remaining, value: value) {
                        var nested = FormValues()
                        if  nested.add(key: remaining, value: value) {
                            return true
                        }
                        self.array.append(nested)
                    }
                    else {
                        self.array[self.array.count - 1] = last
                    }
                }
                else {
                    var nested = FormValues()
                    if nested.add(key: remaining, value: value) {
                        return true
                    }
                    self.array.append(nested)
                }
            }
            else {
                // At the final value
                self.array.append(.init(string: value))
            }
        }
        else {
            // Dictionary Value
            if let remaining = remaining {
                if var existing = self.dictionary[nextComponent] {
                    if existing.add(key: remaining, value: value) {
                        return true
                    }
                    self.dictionary[nextComponent] = existing
                }
                else {
                    var nested = FormValues()
                    if nested.add(key: remaining, value: value) {
                        return true
                    }
                    self.dictionary[nextComponent] = nested
                }
            }
            else {
                // At the final value
                if self.dictionary[nextComponent] != nil {
                    return true
                }
                self.dictionary[nextComponent] = .init(string: value)
            }
        }
        return false
    }
}

private extension FormValues {
    func parse(key: String) -> (nextComponent: String, remaining: String?) {
        guard let startBracket = key.firstIndex(of: "[")
            , let endBracket = key.firstIndex(of: "]")
            else
        {
            return (nextComponent: key, remaining: nil)
        }

        let capturedStart = key.index(after: startBracket)
        let captured = String(key[capturedStart..<endBracket])

        let afterStart = key.index(after: endBracket)
        let after = String(key[afterStart...])
        return (nextComponent: String(key[..<startBracket]), remaining: captured + after)
    }

    var workingRawValues: [(key: [String], value: String)] {
        var output = [(key: [String], value: String)]()

        for (key, value) in self.dictionary {
            if let string = value.string {
                output.append(([key], string))
            }
            for (subKey, subValue) in value.workingRawValues {
                output.append((key: [key] + subKey, value: subValue))
            }
        }

        for value in self.array {
            if let string = value.string {
                output.append((key: [""], value: string))
            }
            for (subKey, subValue) in value.workingRawValues {
                output.append((key: [""] + subKey, value: subValue))
            }
        }

        return output
    }
}
