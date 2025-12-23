import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let container = DependencyContainer.shared
        let appCoordinator = AppCoordinator(window: window, container: container)
        self.appCoordinator = appCoordinator
        
        appCoordinator.start()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        PrivacyScreenService.shared.removePrivacyScreen()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        PrivacyScreenService.shared.setupPrivacyScreen(in: window)
    }
}

class PrivacyScreenService {
    static let shared = PrivacyScreenService()
    private var blurEffectView: UIVisualEffectView?

    private init() {}

    func setupPrivacyScreen(in window: UIWindow?) {
        guard let window = window else { return }
        let blurEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        window.addSubview(blurEffectView)
        self.blurEffectView = blurEffectView
    }

    func removePrivacyScreen() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
    }
}
