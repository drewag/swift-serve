//
//  FormUrlEncoded.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 4/16/17.
//
//

struct FormUrlEncoded: StringKeyValueParser {
    static func parse(_ string: String) -> [String:String] {
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
}
