public enum HTTPMethod {
    case any

    case get
    case post
    case put
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
        }
    }
}
