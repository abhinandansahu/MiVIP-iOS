import XCTest
import MiVIPSdk
import MiVIPApi
@testable import whitelabel_demo

class MiVIPServiceTests: XCTestCase {
    var service: MiVIPServiceProtocol!
    var mockService: MockMiVIPService!
    
    override func setUp() {
        super.setUp()
        mockService = MockMiVIPService()
        service = mockService
    }
    
    func testGetRequestIdFromCode() async throws {
        let requestId = try await service.getRequestId(from: "1234")
        XCTAssertEqual(requestId, "mock-id")
    }
    
    func testStartQRCodeScanCallsService() {
        let vc = UIViewController()
        let delegate = MockRequestStatusDelegate()
        service.startQRCodeScan(vc: vc, delegate: delegate, callbackURL: nil)
        XCTAssertTrue(mockService.qrCodeScanCalled)
    }
}

class MockRequestStatusDelegate: NSObject, RequestStatusDelegate {
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {}
    func error(err: String) {}
}
