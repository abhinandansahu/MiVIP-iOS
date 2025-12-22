import UIKit

class MiVIPCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let router: Router
    private let container: DependencyContainer
    private var viewModel: MiVIPHubViewModel?

    init(router: Router, container: DependencyContainer) {
        self.router = router
        self.container = container
    }

    func start() {
        coordinate(to: .main)
    }

    func coordinate(to route: MiVIPRoute) {
        switch route {
        case .main:
            showMainScreen()
        case .qrScanner(let callbackURL):
            startQRScanner(callbackURL: callbackURL)
        case .request(let id, let callbackURL):
            startRequest(id: id, callbackURL: callbackURL)
        case .requestByCode(let code, let callbackURL):
            startRequestByCode(code: code, callbackURL: callbackURL)
        case .history:
            showHistory()
        case .account:
            showAccount()
        }
    }

    private func showMainScreen() {
        let viewModel = container.makeMiVIPHubViewModel()
        self.viewModel = viewModel
        let viewController = ViewController(viewModel: viewModel, coordinator: self)
        router.setRootViewController(viewController, animated: true)
    }

    private func startQRScanner(callbackURL: String?) {
        guard let viewModel = viewModel else { return }
        viewModel.requestState = .loading
        container.mivipService.startQRCodeScan(
            vc: router.navigationController,
            delegate: viewModel,
            callbackURL: callbackURL
        )
    }

    private func startRequest(id: String, callbackURL: String?) {
        guard let viewModel = viewModel else { return }
        guard !id.isEmpty else {
            viewModel.requestState = .failure(.validation("Request ID cannot be empty"))
            return
        }
        viewModel.requestState = .loading
        container.mivipService.openRequest(
            vc: router.navigationController,
            id: id,
            delegate: viewModel,
            callbackURL: callbackURL
        )
    }

    private func startRequestByCode(code: String, callbackURL: String?) {
        guard let viewModel = viewModel else { return }
        guard !code.isEmpty else {
            viewModel.requestState = .failure(.validation("Request code cannot be empty"))
            return
        }
        viewModel.requestState = .loading

        Task { @MainActor in
            do {
                if let idRequest = try await container.mivipService.getRequestId(from: code) {
                    container.mivipService.openRequest(
                        vc: router.navigationController,
                        id: idRequest,
                        delegate: viewModel,
                        callbackURL: callbackURL
                    )
                } else {
                    viewModel.requestState = .failure(.sdk("Failed to get request ID from code"))
                }
            } catch {
                viewModel.requestState = .failure(.sdk(error.localizedDescription))
            }
        }
    }

    private func showHistory() {
        container.mivipService.showHistory(vc: router.navigationController)
    }

    private func showAccount() {
        container.mivipService.showAccount(vc: router.navigationController)
    }
}
