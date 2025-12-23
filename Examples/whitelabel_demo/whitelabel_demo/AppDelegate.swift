import UIKit
import MiSnapCore

struct Configuration {
    static let miSnapLicenseKey: String? = {
        return Bundle.main.object(forInfoDictionaryKey: "MISNAP_LICENSE_KEY") as? String
    }()
    
    static let apiBaseURL: String = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "HOOYU_API_URL") as? String else {
            return "https://eu-west.id.miteksystems.com"
        }
        return url
    }()
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let license = Configuration.miSnapLicenseKey {
            MiSnapLicenseManager.shared.setLicenseKey(license)
        }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
