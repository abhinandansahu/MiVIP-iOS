import Foundation

struct Configuration {
    /// MiSnap License Key
    static let miSnapLicenseKey: String? = {
        return Bundle.main.object(forInfoDictionaryKey: "MISNAP_LICENSE_KEY") as? String
    }()
    
    /// MiVIP API Configuration
    static let apiBaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "HOOYU_API_URL") as? String else {
            return "https://api.mivip.com" // Fallback
        }
        return url
    }()
}
