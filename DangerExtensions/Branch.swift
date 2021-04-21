enum Branch: RawRepresentable, ExpressibleByStringLiteral {
    /// `develop`
    case develop
    /// `main`
    case main
    /// `release/**`
    case release(String)
    /// `feature/**`
    case feature(String)
    /// `hotfix/**`
    case hotfix(String)
    case other(String)

    init(_ value: String) {
        switch value {
        case "develop": self = .develop
        case "main": self = .main
        default:
            if value.starts(with: "release/") {
                self = .release(String(value.dropFirst(8)))
            } else if value.starts(with: "feature/") {
                self = .feature(String(value.dropFirst(8)))
            } else if value.starts(with: "hotfix/") {
                self = .hotfix(String(value.dropFirst(7)))
            } else {
                self = .other(value)
            }
        }
    }

    init(stringLiteral value: StringLiteralType) {
        self.init(value)
    }

    init?(rawValue: String) {
        self.init(rawValue)
    }

    var rawValue: String {
        switch self {
        case .develop: return "develop"
        case .main: return "main"
        case let .release(str): return "release/\(str)"
        case let .feature(str): return "feature/\(str)"
        case let .hotfix(str): return "hotfix/\(str)"
        case let .other(str): return str
        }
    }
}
