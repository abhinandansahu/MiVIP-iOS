import XCTest
import UIKit
import MiVIPSdk
import MiVIPApi
@testable import whitelabel_demo

class MockRouter: Router {
    var navigationController: UINavigationController = UINavigationController()
    var pushedViewController: UIViewController?
    var rootViewController: UIViewController?
    
    func push(_ viewController: UIViewController, animated: Bool) {
        pushedViewController = viewController
    }
    
    func pop(animated: Bool) {}
    
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {}
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {}
    
    func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        rootViewController = viewController
    }
}

class MockMiVIPService: MiVIPServiceProtocol {
    var qrCodeScanCalled = false
    var openRequestCalled = false
    var showHistoryCalled = false
    var showAccountCalled = false
    
    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?) {
        qrCodeScanCalled = true
    }
    
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) {
        openRequestCalled = true
    }
    
    func getRequestId(from code: String) async throws -> String? {
        return "mock-id"
    }
    
    func showHistory(vc: UIViewController) {
        showHistoryCalled = true
    }
    
    func showAccount(vc: UIViewController) {
        showAccountCalled = true
    }
}

class MiVIPCoordinatorTests: XCTestCase {
    var coordinator: MiVIPCoordinator!
    var mockRouter: MockRouter!
    var mockService: MockMiVIPService!
    var container: DependencyContainer!
    
    override func setUp() {
        super.setUp()
        mockRouter = MockRouter()
        mockService = MockMiVIPService()
        container = DependencyContainer(mivipService: mockService)
        coordinator = MiVIPCoordinator(router: mockRouter, container: container)
    }
    
    func testStartShowsMainScreen() {
        coordinator.start()
        XCTAssertNotNil(mockRouter.rootViewController)
        XCTAssertTrue(mockRouter.rootViewController is ViewController)
    }
    
    func testCoordinateToHistory() {
        coordinator.coordinate(to: .history)
        XCTAssertTrue(mockService.showHistoryCalled)
    }
    
    func testCoordinateToAccount() {
        coordinator.coordinate(to: .account)
        XCTAssertTrue(mockService.showAccountCalled)
    }
}
