public enum HTTPMethod: String {
    case any

    case get
    case post
    case put
    case delete
}

extension HTTPMethod {
    func matches(_ other: HTTPMethod) -> Bool {
        switch self {
        case .any:
            return true
        case .get:
            switch other {
            case .get, .any:
                return true
            default:
                return false
            }
        case .post:
            switch other {
            case .post, .any:
                return true
            default:
                return false
            }
        case .put:
            switch other {
            case .put, .any:
                return true
            default:
                return false
            }
        case .delete:
            switch other {
            case .delete, .any:
                return true
            default:
                return false
            }
        }
    }
}
