import UIKit

class DependencyContainer {
    static let shared = DependencyContainer()
    
    let mivipService: MiVIPServiceProtocol
    let configuration: SecureConfiguration
    
    private init() {
        do {
            self.mivipService = try MiVIPService()
        } catch {
            fatalError("Failed to initialize MiVIPService: \(error)")
        }
        self.configuration = SecureConfiguration.shared
    }
    
    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        return AppCoordinator(window: window, container: self)
    }
    
    func makeMiVIPCoordinator(router: Router) -> MiVIPCoordinator {
        return MiVIPCoordinator(router: router, container: self)
    }
    
    func makeMiVIPHubViewModel() -> MiVIPHubViewModel {
        return MiVIPHubViewModel()
    }
}
