//
//  FormUrlEncoded.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 4/16/17.
//
//

import Foundation

public struct FormUrlEncoded: StringKeyValueParser {
    public static func parse(_ string: String) -> [String:String] {
        var output = [String:String]()

        for pair in string.components(separatedBy: "&") {
            let components = pair.components(separatedBy: "=")
            guard components.count == 2 else {
                continue
            }

            func unencode(_ string: String) -> String? {
                let withSpaces = string.replacingOccurrences(of: "+", with: " ")
                return withSpaces.removingPercentEncoding
            }

            guard let key = unencode(components[0]) else {
                continue
            }
            guard let value = unencode(components[1]) else {
                continue
            }
            output[key] = value
        }

        return output
    }

    public static func encode(_ data: [String:String]) -> String {
        var output = ""

        let characterSet = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789–_.~")
        func escape(_ string: String) -> String {
            return string.addingPercentEncoding(withAllowedCharacters: characterSet) ?? ""
        }

        for (key, value) in data {
            if !output.isEmpty {
                output += "&"
            }
            output += "\(escape(key))=\(escape(value))"
        }

        return output
    }
}
