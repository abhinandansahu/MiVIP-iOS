import UIKit

protocol DependencyProvider {
    var mivipService: MiVIPServiceProtocol { get }
}

class DependencyContainer: DependencyProvider {
    static let shared = DependencyContainer()
    
    let mivipService: MiVIPServiceProtocol
    
    init(mivipService: MiVIPServiceProtocol? = nil) {
        if let service = mivipService {
            self.mivipService = service
        } else {
            do {
                self.mivipService = try MiVIPService()
            } catch {
                fatalError("Failed to initialize MiVIPService: \(error)")
            }
        }
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
