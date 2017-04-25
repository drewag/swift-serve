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
    case html

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
        case "text/html":
            self = .html
        case "appliction/pdf":
            self = .pdf
        default:
            self = .other(string)
        }
    }

    public static func types(from string: String?) -> [ContentType] {
        guard let string = string else {
            return []
        }

        var output = [ContentType]()
        for type in string.components(separatedBy: ",") {
            output.append(ContentType(type))
        }
        return output
    }
}

extension ContentType: Equatable {
    public static func ==(lhs: ContentType, rhs: ContentType) -> Bool {
        switch lhs {
        case .pdf:
            switch rhs {
            case .pdf:
                return true
            default:
                return false
            }
        case .png:
            switch rhs {
            case .png:
                return true
            default:
                return false
            }
        case .jpg:
            switch rhs {
            case .jpg:
                return true
            default:
                return false
            }
        case .html:
            switch rhs {
            case .html:
                return true
            default:
                return false
            }
        case .multipartFormData:
            switch rhs {
            case .multipartFormData:
                return true
            default:
                return false
            }
        case .none:
            switch rhs {
            case .none:
                return true
            default:
                return false
            }
        case .other(let left):
            switch rhs {
            case .other(let right):
                return left == right
            default:
                return false
            }
        }
    }
}
