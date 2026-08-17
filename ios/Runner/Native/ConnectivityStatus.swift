import Network

enum AppConnectivityStatus {
    case wifi
    case mobile
    case none

    static func from(path: NWPath) -> AppConnectivityStatus {
        guard path.status == .satisfied else {
            return .none
        }
        if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            return .wifi
        }
        if path.usesInterfaceType(.cellular) {
            return .mobile
        }
        return .none
    }

    var channelValue: String {
        switch self {
        case .wifi: return "wifi"
        case .mobile: return "mobile"
        case .none: return "none"
        }
    }

    var pigeonStatus: ApiConnectivityStatus {
        switch self {
        case .wifi: return .wifi
        case .mobile: return .mobile
        case .none: return .none
        }
    }
}
