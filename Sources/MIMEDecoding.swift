//
//  MIMEDecoding.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 1/28/18.
//

import Foundation

extension Data {
    public init(data: Data, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding) {
        switch transferEncoding {
        case .base64:
            guard let base64String = String(data: data, encoding: characterEncoding)?.replacingOccurrences(of: "\n", with: "") else {
                self.init(data)
                return
            }
            self.init(Data(base64Encoded: base64String) ?? data)
        default:
            let string = String(data: data, transferEncoding: transferEncoding, characterEncoding: characterEncoding)
            self.init(string?.data(using: characterEncoding) ?? Data())
        }
    }
}

extension String {
    public init(string: String, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding) {
        switch transferEncoding {
        case .quotedPrintable:
            self = string.decodingQuotedPrintable(using: characterEncoding) ?? string
        case .eightbit, .sevenBit, .none, .other, .binary:
            self = string
        case .base64:
            let raw = string.replacingOccurrences(of: "\n", with: "")
            guard let data = Data(base64Encoded: raw) else {
                self = string
                return
            }
            self = String(data: data, encoding: characterEncoding) ?? string
        }
    }

    public init?(data: Data, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding)  {
        switch transferEncoding {
        case .quotedPrintable:
            guard let string = String(data: data, encoding: characterEncoding)?.decodingQuotedPrintable(using: characterEncoding) else {
                return nil
            }
            self.init(string)
        case .eightbit, .sevenBit, .none, .other:
            self.init(data: data, encoding: characterEncoding)
        case .binary:
            return nil
        case .base64:
            guard let base64String = String(data: data, encoding: characterEncoding)?.replacingOccurrences(of: "\n", with: "")
                , let base64 = Data(base64Encoded: base64String) else {
                    return nil
            }
            self.init(data: base64, encoding: characterEncoding)
        }
    }
}

private extension String {
    enum PercentMode {
        case none, percent(String?)
    }

    func removingPercentEncoding(using encoding: String.Encoding) -> String? {
        var output = ""
        var mode = PercentMode.none

        func cancelEscape(_ first: String?) {
            output.append("%")
            if let first = first {
                output += "\(first)"
            }
            mode = .none
        }

        for character in self {
            switch character {
            case "%":
                switch mode {
                case .none:
                    mode = .percent(nil)
                case .percent(let first):
                    cancelEscape(first)
                }
            case "0","1","2","3","4","5","6","7","8","9":
                switch mode {
                case .none:
                    output.append(character)
                case .percent(let first):
                    guard let first = first else {
                        mode = .percent("\(character)")
                        break
                    }
                    let hexString = "\(first)\(character)"
                    let bytes = [UInt8(hexString, radix: 16)!]
                    let decoded = String(data: Data(bytes), encoding: encoding) ?? "?"
                    output += decoded
                }
            default:
                switch mode {
                case .none:
                    output.append(character)
                case let .percent(first):
                    cancelEscape(first)
                }
            }
        }
        return output
    }

    func decodingQuotedPrintable(using encoding: String.Encoding) -> String? {
        let next = self
            .replacingOccurrences(of: "=\r\n", with: "")
            .replacingOccurrences(of: "=\n", with: "")
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "=", with: "%")
            .replacingOccurrences(of: "\n", with: "%0A")
        return next.removingPercentEncoding(using: encoding)
    }
}
