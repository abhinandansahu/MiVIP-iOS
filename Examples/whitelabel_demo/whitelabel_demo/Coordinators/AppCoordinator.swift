import UIKit

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let window: UIWindow
    private let container: DependencyContainer

    init(window: UIWindow, container: DependencyContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        let router = AppRouter()
        let mivipCoordinator = container.makeMiVIPCoordinator(router: router)
        childCoordinators.append(mivipCoordinator)

        window.rootViewController = router.navigationController
        window.makeKeyAndVisible()

        mivipCoordinator.start()
    }
}
