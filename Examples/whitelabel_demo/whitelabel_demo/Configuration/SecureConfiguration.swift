import Foundation

struct Configuration {
    /// MiSnap License Key - Replace with your actual license key
    static let miSnapLicenseKey: String? = {
        // Try to load from Info.plist first
        if let key = Bundle.main.object(forInfoDictionaryKey: "MISNAP_LICENSE_KEY") as? String ?? 
            Bundle.main.object(forInfoDictionaryKey: "MiSnapLicenseKey") as? String,
           !key.isEmpty {
            return key
        }
        
        // Fallback to hardcoded value (not recommended for production)
        return "YOUR MISNAP LICENSE HERE"
    }()
    
    /// MiVIP API Configuration
    static let apiBaseURL: String = {
        if let url = Bundle.main.object(forInfoDictionaryKey: "MiVIPAPIBaseURL") as? String,
           !url.isEmpty {
            return url
        }
        return "https://api.mivip.com" // Replace with actual base URL
    }()
}
