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

    static func parts(in data: Data, usingBoundary boundary: String) -> [MultiFormPart] {
        guard let firstBoundaryData = "--\(boundary)\r\n".data(using: .utf8)
            , let midBoundaryData = "\r\n--\(boundary)\r\n".data(using: .utf8)
            , let endBoundaryData = "\r\n--\(boundary)--".data(using: .utf8)
            , let firstBoundaryRange = data.range(of: firstBoundaryData)
            else
        {
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
            output.append(MultiFormPart(range: finalRange, in: data))
        }

        return output
    }

    private init(range: Range<Data.Index>, in data: Data) {
        let newLineData = "\r\n".data(using: .utf8)!

        var dataStartIndex = range.lowerBound
        let afterPossibleNewLine = data.index(dataStartIndex, offsetBy: 2)
        switch data.subdata(in: range.lowerBound ..< afterPossibleNewLine) {
        case newLineData:
            // has no header
            dataStartIndex = afterPossibleNewLine
        default:
            // has header
            let endOfHeaderData = "\r\n\r\n".data(using: .utf8)!
            guard let headerSplitterRange = data.range(of: endOfHeaderData, in: range)
                , let header = String(data: data.subdata(in: range.lowerBound ..< headerSplitterRange.lowerBound), encoding: .utf8)
                else
            {
                break
            }

            var name: String?
            var contentType: ContentType?
            for line in header.components(separatedBy: "\r\n") {
                guard !line.isEmpty else {
                    continue
                }
                var components = line.components(separatedBy: ":")
                let componentName = components.removeFirst()
                let remaining = components.joined(separator: ":")
                switch componentName {
                case "Content-Disposition":
                    name = StructuredHeader.parse(remaining)["name"]
                case "Content-Type":
                    contentType = ContentType(remaining)
                default:
                    break
                }
            }

            self.data = data.subdata(in: headerSplitterRange.upperBound ..< range.upperBound)
            self.name = name
            self.contentType = contentType
            return
        }

        self.data = data.subdata(in: dataStartIndex ..< range.upperBound)
        self.name = nil
        self.contentType = nil
    }
}
