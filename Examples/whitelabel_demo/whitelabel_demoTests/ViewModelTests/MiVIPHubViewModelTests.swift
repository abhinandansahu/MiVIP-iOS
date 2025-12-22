import XCTest
import Combine
import MiVIPSdk
import MiVIPApi
@testable import whitelabel_demo

class MiVIPHubViewModelTests: XCTestCase {
    var viewModel: MiVIPHubViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        viewModel = MiVIPHubViewModel()
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        cancellables = nil
        super.tearDown()
    }
    
    func testInitialStateIsIdle() {
        XCTAssertEqual(viewModel.requestState, .idle)
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
                    if case .sdk(let message) = error {
                        XCTAssertEqual(message, "Test Error")
                    } else {
                        XCTFail("Expected sdk error")
                    }
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.error(err: "Test Error")
        
        wait(for: [expectation], timeout: 1.0)
    }
}
