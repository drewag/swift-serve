//
//  MimeDecoder.swift
//  SwiftServe
//
//  Created by Andrew J Wagner on 2/23/18.
//

import Foundation
import Swiftlier

public struct MimePart: ErrorGenerating {
    public enum Content {
        case pdf(Data)
        case png(Data)
        case jpg(Data)
        case octetStream(Data)
        case html(String)
        case plain(String)
        case zip(Data)
        case csv(Data)

        case multipartFormData([MimePart])
        case multipartAlternative([MimePart])
        case multipartMixed([MimePart])
        case multipartRelated([MimePart])
        case multipartReport([MimePart], type: String)

        case none
    }

    let name: String?
    public let content: Content
    let headers: [String:String]
    let contentType: ContentType
    let contentTransferEncoding: ContentTransferEncoding
    let contentDisposition: ContentDisposition

    public var plain: String? {
        switch self.content {
        case .plain(let plain):
            return plain
        default:
            return nil
        }
    }

    init(data: Data) throws {
        guard let string = String(data: data, encoding: .ascii) else {
            throw MimePart.error("parsing", because: "data is not valid ascii")
        }
        try self.init(rawContents: string)
    }

    init(body: Data, headers: [String:String], contentType: ContentType, contentTransferEncoding: ContentTransferEncoding, contentDisposition: ContentDisposition) throws {
        guard let string = String(data: body, encoding: .ascii) else {
            throw MimePart.error("parsing", because: "data is not valid ascii")
        }
        try self.init(body: string, headers: headers, contentType: contentType, contentTransferEncoding: contentTransferEncoding, contentDisposition: contentDisposition)
    }

    init(body: String, headers: [String:String], contentType: ContentType, contentTransferEncoding: ContentTransferEncoding, contentDisposition: ContentDisposition) throws {
        switch contentDisposition {
        case .attachment(let name):
            self.name = name
        case .formData(let name):
            self.name = name
        case .none, .other, .inline:
            self.name = nil
        }

        switch contentType {
        case .other(let other):
            throw MimePart.error("parsing", because: "an unknown content type was found '\(other)'")
        case .html(let encoding):
            self.content = .html(type(of: self).string(from: body, transferEncoding: contentTransferEncoding, characterEncoding: encoding))
        case .none:
            self.content = .plain(type(of: self).string(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .plainText(let encoding):
            self.content = .plain(type(of: self).string(from: body, transferEncoding: contentTransferEncoding, characterEncoding: encoding))
        case .csv:
            self.content = .csv(type(of: self).data(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .jpg:
            self.content = .jpg(type(of: self).data(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .png:
            self.content = .png(type(of: self).data(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .pdf:
            self.content = .pdf(type(of: self).data(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .octetStream:
            self.content = .octetStream(type(of: self).data(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .zip:
            self.content = .zip(type(of: self).data(from: body, transferEncoding: contentTransferEncoding, characterEncoding: .ascii))
        case .multipartFormData(let boundary):
            let parts = try MimePart.parts(in: body, usingBoundary: boundary)
            self.content = .multipartFormData(parts)
        case .multipartAlternative(let boundary):
            let parts = try MimePart.parts(in: body, usingBoundary: boundary)
            self.content = .multipartAlternative(parts)
        case .multipartMixed(let boundary):
            let parts = try MimePart.parts(in: body, usingBoundary: boundary)
            self.content = .multipartMixed(parts)
        case .multipartRelated(let boundary):
            let parts = try MimePart.parts(in: body, usingBoundary: boundary)
            self.content = .multipartRelated(parts)
        case let .multipartReport(boundary, reportType):
            let parts = try MimePart.parts(in: body, usingBoundary: boundary)
            self.content = .multipartReport(parts, type: reportType)

        }

        self.headers = headers
        self.contentType = contentType
        self.contentTransferEncoding = contentTransferEncoding
        self.contentDisposition = contentDisposition
    }

    init(rawContents: String, newline: String? = nil) throws {
        var headers = [String:String]()
        var fullLine = ""

        func processFullLine() {
            guard !fullLine.isEmpty else {
                return
            }

            //            print("Processing: \(fullLine)")
            let components = fullLine.components(separatedBy: ": ")
            guard components.count >= 2 else {
                return
            }

            headers[components[0].lowercased()] = components[1...].joined(separator: ": ")
        }

        var startedBody = false
        var body = ""

        let finalNewLine: String
        if let newline = newline {
            finalNewLine = newline
        }
        else {
            if rawContents.contains("\r\n") {
                finalNewLine = "\r\n"
            }
            else {
                finalNewLine = "\n"
            }
        }

        for line in rawContents.components(separatedBy: finalNewLine) {
            guard !startedBody else {
                if !body.isEmpty {
                    body += finalNewLine
                }
                body += line
                continue
            }

            guard !line.isEmpty else {
                // End of headers
                startedBody = true
                continue
            }

            if line.hasPrefix(" ") || line.hasPrefix("\t") {
                // Continuation of last line
                fullLine += " " + line.trimmingWhitespaceOnEnds
            }
            else {
                // New line

                // Process previous line
                processFullLine()

                // Setup next line
                fullLine = line
            }
        }

        processFullLine()

        try self.init(
            body: body,
            headers: headers,
            contentType: ContentType(headers["content-type"]),
            contentTransferEncoding: ContentTransferEncoding(headers["content-transfer-encoding"]),
            contentDisposition: ContentDisposition(headers["content-disposition"])
        )
    }

    public subscript(name: String) -> MimePart? {
        let foundParts: [MimePart]
        switch content {
        case .multipartAlternative(let parts):
            foundParts = parts
        case .multipartMixed(let parts):
            foundParts = parts
        case .multipartRelated(let parts):
            foundParts = parts
        case .multipartReport(let parts, type: _):
            foundParts = parts
        case .multipartFormData(let parts):
            foundParts = parts
        default:
            return nil
        }

        return foundParts.first(where: {$0.name == name})
    }

    public static func parts(in body: String, usingBoundary boundary: String) throws -> [MimePart] {
        let data = body.data(using: .ascii) ?? Data()
        return try self.parts(in: data, usingBoundary: boundary)
    }

    public static func parts(in data: Data, usingBoundary boundary: String) throws -> [MimePart] {
        let firstBoundaryRange: Range<Data.Index>
        let midBoundaryData: Data
        let endBoundaryData: Data
        let newLine: String

        if let bothFirstBoundaryData = "--\(boundary)\r\n".data(using: .utf8)
            , let bothMidBoundaryData = "\r\n--\(boundary)\r\n".data(using: .utf8)
            , let bothEndBoundaryData = "\r\n--\(boundary)--".data(using: .utf8)
            , let bothFirstBoundaryRange = data.range(of: bothFirstBoundaryData)
        {
            firstBoundaryRange = bothFirstBoundaryRange
            midBoundaryData = bothMidBoundaryData
            endBoundaryData = bothEndBoundaryData
            newLine = "\r\n"
        }
        else if let singleFirstBoundaryData = "--\(boundary)\n".data(using: .utf8)
            , let singleMidBoundaryData = "\n--\(boundary)\n".data(using: .utf8)
            , let singleEndBoundaryData = "\n--\(boundary)--".data(using: .utf8)
            , let singleFirstBoundaryRange = data.range(of: singleFirstBoundaryData)
        {
            firstBoundaryRange = singleFirstBoundaryRange
            midBoundaryData = singleMidBoundaryData
            endBoundaryData = singleEndBoundaryData
            newLine = "\n"
        }
        else {
            return []
        }

        var output = [MimePart]()

        let ranges = data.ranges(separatedBy: midBoundaryData, in: firstBoundaryRange.upperBound ..< data.count)
        for (index, range) in ranges.enumerated() {
            let finalRange: Range<Data.Index>
            if index == ranges.count - 1, let endRange = data.range(of: endBoundaryData, in: range) {
                finalRange = range.lowerBound ..< endRange.lowerBound
            }
            else {
                finalRange = range
            }
            guard let string = String(data: data.subdata(in: finalRange), encoding: .ascii) else {
                continue
            }
            output.append(try MimePart(rawContents: string, newline: newLine))
        }

        return output
    }
}

private extension MimePart {
    static func data(from data: Data, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding) -> Data {
        switch transferEncoding {
        case .base64:
            guard let base64String = String(data: data, encoding: characterEncoding)?.replacingOccurrences(of: "\n", with: "") else {
                return data
            }
            return Data(base64Encoded: base64String) ?? data
        default:
            return data
        }
    }

    static func data(from string: String, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding) -> Data {
        switch transferEncoding {
        case .base64:
            let base64String = string.replacingOccurrences(of: "\n", with: "")
            return Data(base64Encoded: base64String) ?? Data()
        default:
            return string.data(using: characterEncoding) ?? Data()
        }
    }

    static func string(from string: String, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding) -> String {
        switch transferEncoding {
        case .quotedPrintable:
            return string.decodingQuotedPrintable(using: characterEncoding) ?? string
        case .eightbit, .sevenBit, .none, .other, .binary:
            return string
        case .base64:
            let raw = string.replacingOccurrences(of: "\n", with: "")
            guard let data = Data(base64Encoded: raw) else {
                return string
            }
            return String(data: data, encoding: characterEncoding) ?? string
        }
    }

    static func string(data: Data, transferEncoding: ContentTransferEncoding, characterEncoding: String.Encoding) -> String? {
        switch transferEncoding {
        case .quotedPrintable:
            return String(data: data, encoding: characterEncoding)?.decodingQuotedPrintable(using: characterEncoding)
        case .eightbit, .sevenBit, .none, .other:
            return String(data: data, encoding: characterEncoding)
        case .binary:
            return nil
        case .base64:
            guard let base64String = String(data: data, encoding: characterEncoding)?.replacingOccurrences(of: "\n", with: "")
                , let base64 = Data(base64Encoded: base64String) else {
                    return nil
            }
            return String(data: base64, encoding: characterEncoding)
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

