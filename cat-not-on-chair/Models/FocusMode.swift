import Foundation

enum FocusMode: String, CaseIterable {
    case strict = "Strict"
    case whitelist = "Whitelist"
    case relax = "Relax"
    
    var description: String {
        switch self {
        case .strict:
            return "Block all apps during focus time"
        case .whitelist:
            return "Allow selected apps during focus time"
        case .relax:
            return "Allow all apps during focus time"
        }
    }
} 