//
//  MultiPartPart.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 4/16/17.
//
//

import Foundation

public struct MultiFormPart {
    public let data: Data
    public let name: String?
    public let contentType: ContentType?
    public let contentTransferEncoding: ContentTransferEncoding
    public let contentDisposition: ContentDisposition
    public let newLine: String

    public var contents: String? {
        switch self.contentType ?? .none {
        case .plainText(let encoding):
            return String(data: self.data, transferEncoding: self.contentTransferEncoding, characterEncoding: encoding)
        case .html(let encoding):
            return String(data: self.data, transferEncoding: self.contentTransferEncoding, characterEncoding: encoding)
        default:
            return String(data: self.data, transferEncoding: self.contentTransferEncoding, characterEncoding: .utf8)
        }
    }

    public var parsedBody: Data {
        switch self.contentType ?? .none {
        case .plainText(let encoding):
            return Data(data: self.data, transferEncoding: self.contentTransferEncoding, characterEncoding: encoding)
        case .html(let encoding):
            return Data(data: self.data, transferEncoding: self.contentTransferEncoding, characterEncoding: encoding)
        default:
            return Data(data: self.data, transferEncoding: self.contentTransferEncoding, characterEncoding: .utf8)
        }
    }

    public static func parts(in data: Data, usingBoundary boundary: String) -> [MultiFormPart] {
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

        var output = [MultiFormPart]()

        let ranges = data.ranges(separatedBy: midBoundaryData, in: firstBoundaryRange.upperBound ..< data.count)
        for (index, range) in ranges.enumerated() {
            let finalRange: Range<Data.Index>
            if index == ranges.count - 1, let endRange = data.range(of: endBoundaryData, in: range) {
                finalRange = range.lowerBound ..< endRange.lowerBound
            }
            else {
                finalRange = range
            }
            output.append(MultiFormPart(range: finalRange, newLine: newLine, in: data))
        }

        return output
    }

    private init(range: Range<Data.Index>, newLine: String, in data: Data) {
        let newLineData = newLine.data(using: .utf8)!
        self.newLine = newLine

        var dataStartIndex = range.lowerBound
        let afterPossibleNewLine = data.index(dataStartIndex, offsetBy: 2)
        switch data.subdata(in: range.lowerBound ..< afterPossibleNewLine) {
        case newLineData:
            // has no header
            dataStartIndex = afterPossibleNewLine
        default:
            // has header
            let endOfHeaderData = "\(newLine)\(newLine)".data(using: .utf8)!
            guard let headerSplitterRange = data.range(of: endOfHeaderData, in: range)
                , let header = String(data: data.subdata(in: range.lowerBound ..< headerSplitterRange.lowerBound), encoding: .utf8)
                else
            {
                break
            }

            var name: String?
            var contentType: ContentType?
            var contentDisposition: ContentDisposition = .none
            var contentTransferEncoding: String?

            var fullLine = ""

            func processFullLine() {
                guard !fullLine.isEmpty else {
                    return
                }

                let components = fullLine.components(separatedBy: ": ")
                guard components.count >= 2 else {
                    return
                }

                let remaining = components[1...].joined(separator: ": ")
                switch components[0].lowercased() {
                case "content-disposition":
                    name = StructuredHeader.parse(remaining)["name"]
                    contentDisposition = ContentDisposition(remaining)
                case "content-type":
                    contentType = ContentType(remaining)
                case "content-transfer-encoding":
                    contentTransferEncoding = remaining
                default:
                    break
                }
            }

            for line in header.components(separatedBy: newLine) {
                guard !line.isEmpty else {
                    // End of headers
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

            self.contentTransferEncoding = ContentTransferEncoding(contentTransferEncoding)
            self.data = data.subdata(in: headerSplitterRange.upperBound ..< range.upperBound)
            self.name = name
            self.contentType = contentType
            self.contentDisposition = contentDisposition
            return
        }

        self.data = data.subdata(in: dataStartIndex ..< range.upperBound)
        self.name = nil
        self.contentType = nil
        self.contentTransferEncoding = .none
        self.contentDisposition = .none
    }
}
