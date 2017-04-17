//
//  ContentType.swift
//  file-sync-services
//
//  Created by Andrew J Wagner on 4/16/17.
//
//

public enum ContentType {
    case pdf
    case png
    case jpg

    case multipartFormData(boundary: String)

    case none
    case other(String)

    public init(_ string: String?) {
        guard let string = string else {
            self = .none
            return
        }

        var parts = string.components(separatedBy: ";")

        switch parts.removeFirst() {
        case "multipart/form-data" where parts.count > 0:
            let remaining = parts.joined(separator: ";")
            guard let boundary = StructuredHeader.parse(remaining)["boundary"] else {
                self = .other(string)
                return
            }
            self = .multipartFormData(boundary: boundary)
        case "appliction/pdf":
            self = .pdf
        default:
            self = .other(string)
        }
    }
}
