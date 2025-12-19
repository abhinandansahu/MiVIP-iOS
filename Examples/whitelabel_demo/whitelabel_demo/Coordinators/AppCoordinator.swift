import UIKit

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let window: UIWindow

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let navigationController = UINavigationController()
        let mivipCoordinator = MiVIPCoordinator(navigationController: navigationController)
        childCoordinators.append(mivipCoordinator)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        mivipCoordinator.start()
    }
}
