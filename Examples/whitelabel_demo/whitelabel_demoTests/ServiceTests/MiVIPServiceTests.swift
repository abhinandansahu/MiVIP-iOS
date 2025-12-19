import XCTest
import MiVIPSdk
import MiVIPApi
@testable import whitelabel_demo

class MiVIPServiceTests: XCTestCase {
    var service: MockMiVIPService!
    
    override func setUp() {
        super.setUp()
        service = MockMiVIPService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    func testStartQRCodeScan() {
        let vc = UIViewController()
        let delegate = MockRequestStatusDelegate()
        service.startQRCodeScan(vc: vc, delegate: delegate, callbackURL: "https://example.com")
        XCTAssertTrue(service.qrCodeScanCalled)
    }
    
    func testOpenRequest() {
        let vc = UIViewController()
        let delegate = MockRequestStatusDelegate()
        service.openRequest(vc: vc, id: "uuid", delegate: delegate, callbackURL: nil)
        XCTAssertTrue(service.openRequestCalled)
    }
}

class MockRequestStatusDelegate: NSObject, RequestStatusDelegate {
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {}
    func error(err: String) {}
}
