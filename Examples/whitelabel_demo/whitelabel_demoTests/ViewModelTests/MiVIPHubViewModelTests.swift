import XCTest
import Combine
import MiVIPSdk
import MiVIPApi
@testable import whitelabel_demo

class MockMiVIPService: MiVIPServiceProtocol {
    var qrCodeScanCalled = false
    var openRequestCalled = false
    var openRequestByCodeCalled = false
    var showHistoryCalled = false
    var showAccountCalled = false
    
    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?) {
        qrCodeScanCalled = true
    }
    
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) {
        openRequestCalled = true
    }
    
    func openRequestByCode(vc: UIViewController, code: String, delegate: RequestStatusDelegate, callbackURL: String?, completion: @escaping (String?, Error?) -> Void) {
        openRequestByCodeCalled = true
        completion("mock-id", nil)
    }
    
    func showHistory(vc: UIViewController) {
        showHistoryCalled = true
    }
    
    func showAccount(vc: UIViewController) {
        showAccountCalled = true
    }
}

class MiVIPHubViewModelTests: XCTestCase {
    var viewModel: MiVIPHubViewModel!
    var mockService: MockMiVIPService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockService = MockMiVIPService()
        viewModel = MiVIPHubViewModel(mivipService: mockService)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockService = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialStateIsIdle() {
        XCTAssertEqual(viewModel.requestState, .idle)
    }
    
    func testQRCodeScanStartsLoading() {
        viewModel.startQRCodeScan(from: UIViewController(), callbackURL: nil)
        XCTAssertEqual(viewModel.requestState, .loading)
        XCTAssertTrue(mockService.qrCodeScanCalled)
    }
    
    func testOpenRequestStartsLoading() {
        viewModel.openRequest(from: UIViewController(), id: "test-id", callbackURL: nil)
        XCTAssertEqual(viewModel.requestState, .loading)
        XCTAssertTrue(mockService.openRequestCalled)
    }
    
    func testOpenRequestWithEmptyIdSetsFailure() {
        viewModel.openRequest(from: UIViewController(), id: "", callbackURL: nil)
        if case .failure(let error) = viewModel.requestState {
            XCTAssertEqual(error.userMessage, "Request ID cannot be empty")
        } else {
            XCTFail("Expected failure state")
        }
    }
    
    func testStatusUpdateToSuccess() {
        let expectation = XCTestExpectation(description: "State updated to success")
        
        viewModel.$requestState
            .dropFirst()
            .sink { state in
                if case .success(let result) = state {
                    XCTAssertEqual(result, .PASS)
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.status(status: .COMPLETED, result: .PASS, scoreResponse: nil, request: nil)
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testErrorUpdateToFailure() {
        let expectation = XCTestExpectation(description: "State updated to failure")
        
        viewModel.$requestState
            .dropFirst()
            .sink { state in
                if case .failure(let error) = state {
                    XCTAssertEqual(error.userMessage, "An error occurred: Test Error")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.error(err: "Test Error")
        
        wait(for: [expectation], timeout: 1.0)
    }
}
