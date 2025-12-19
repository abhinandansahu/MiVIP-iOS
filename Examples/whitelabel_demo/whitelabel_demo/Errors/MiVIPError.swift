import Foundation
import MiVIPSdk

enum MiVIPError: Error {
    case license(MiVIPHub.LicenseError)
    case network(String)
    case validation(String)
    case sdk(String)
    case unknown

    var userMessage: String {
        switch self {
        case .license(let error):
            return "License validation failed: \(error.rawValue). Please contact support."
        case .network(let message):
            return "Network connection issue: \(message). Please check your internet connection."
        case .validation(let message):
            return "Validation error: \(message)"
        case .sdk(let message):
            return "An SDK error occurred: \(message)"
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .network, .validation:
            return true
        case .license, .sdk, .unknown:
            return false
        }
    }
}
