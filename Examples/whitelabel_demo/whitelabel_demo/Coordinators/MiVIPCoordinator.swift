import UIKit

class MiVIPCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        showMainScreen()
    }

    private func showMainScreen() {
        do {
            let service = try MiVIPService()
            let viewModel = MiVIPHubViewModel(mivipService: service)
            let viewController = ViewController(viewModel: viewModel, coordinator: self)
            navigationController.pushViewController(viewController, animated: false)
        } catch {
            assertionFailure("Failed to initialize MiVIPService: \(error)")
        }
    }

    func showQRScanner(from vc: UIViewController, viewModel: MiVIPHubViewModel, callbackURL: String?) {
        viewModel.startQRCodeScan(from: vc, callbackURL: callbackURL)
    }

    func showRequest(from vc: UIViewController, viewModel: MiVIPHubViewModel, id: String, callbackURL: String?) {
        viewModel.openRequest(from: vc, id: id, callbackURL: callbackURL)
    }

    func showRequestByCode(from vc: UIViewController, viewModel: MiVIPHubViewModel, code: String, callbackURL: String?) {
        viewModel.openRequestByCode(from: vc, code: code, callbackURL: callbackURL)
    }

    func showHistory(from vc: UIViewController, viewModel: MiVIPHubViewModel) {
        viewModel.showHistory(from: vc)
    }

    func showAccount(from vc: UIViewController, viewModel: MiVIPHubViewModel) {
        viewModel.showAccount(from: vc)
    }
}
