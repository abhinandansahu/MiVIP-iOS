import Foundation

struct Configuration {
    static var miSnapLicenseKey: String? {
        Bundle.main.infoDictionary?["MISNAP_LICENSE_KEY"] as? String ?? "YOUR MISNAP LICENSE HERE"
    }
}
