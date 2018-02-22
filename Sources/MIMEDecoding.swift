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
    func bytesByRemovingPercentEncoding(using encoding: String.Encoding) -> Data {
        struct My {
            static let regex = try! NSRegularExpression(pattern: "(%[0-9A-F]{2})|(.)", options: .caseInsensitive)
        }
        var bytes = Data()
        let nsSelf = self as NSString
        for match in My.regex.matches(in: self, range: NSRange(0..<self.utf16.count)) {
            if match.rangeAt(1).location != NSNotFound {
                let hexString = nsSelf.substring(with: NSMakeRange(match.rangeAt(1).location+1, 2))
                bytes.append(UInt8(hexString, radix: 16)!)
            } else {
                let singleChar = nsSelf.substring(with: match.rangeAt(2))
                bytes.append(singleChar.data(using: encoding) ?? "?".data(using: .ascii)!)
            }
        }
        return bytes
    }

    func removingPercentEncoding(using encoding: String.Encoding) -> String? {
        return String(data: bytesByRemovingPercentEncoding(using: encoding), encoding: encoding)
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
