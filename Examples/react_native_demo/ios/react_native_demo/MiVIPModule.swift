import Foundation
import MiVIPSdk
import MiVIPApi
import React

@objc(MiVIPModule)
class MiVIPModule: NSObject, RequestStatusDelegate {
    
    private var mivipHub: MiVIPHub?
    private var resolve: RCTPromiseResolveBlock?
    private var reject: RCTPromiseRejectBlock?
    
    override init() {
        super.init()
        do {
            self.mivipHub = try MiVIPHub()
            configureHub()
        } catch {
            print("MiVIPModule: Failed to initialize MiVIPHub: \(error)")
        }
    }
    
    @objc static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    private func configureHub() {
        guard let hub = mivipHub else { return }
        hub.setSoundsDisabled(true)
        hub.setReusableEnabled(false)
        // Configure fonts if available in the main bundle
        hub.setFontNameRegular(fontName: "WorkSans-Regular")
    }
    
    @objc(startRequest:resolver:rejecter:)
    func startRequest(id: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolver
        self.reject = rejecter
        
        DispatchQueue.main.async {
            guard let hub = self.mivipHub,
                  let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
                rejecter("E_INIT_FAILED", "SDK or RootVC not initialized", nil)
                return
            }
            hub.request(vc: rootVC, miVipRequestId: id, requestStatusDelegate: self)
        }
    }
    
    @objc(scanQRCode:rejecter:)
    func scanQRCode(resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolver
        self.reject = rejecter
        
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
                rejecter("E_VC_FAILED", "RootVC not found", nil)
                return
            }
            
            let scanner = CustomQRScannerViewController()
            scanner.onCodeScanned = { [weak self, weak scanner] code in
                scanner?.dismiss(animated: true) {
                    if let uuid = self?.extractUUID(from: code) {
                        self?.startRequest(id: uuid, resolver: resolver, rejecter: rejecter)
                    } else {
                        rejecter("E_INVALID_QR", "No Request ID found in QR Code", nil)
                    }
                }
            }
            rootVC.present(scanner, animated: true)
        }
    }
    
    private func extractUUID(from string: String) -> String? {
        let pattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(string.startIndex..., in: string)
        if let match = regex?.firstMatch(in: string, range: range), let r = Range(match.range, in: string) {
            return String(string[r])
        }
        return nil
    }
    
    // MARK: - RequestStatusDelegate
    
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        if let result = result {
            self.resolve?(String(describing: result))
            self.cleanup()
        }
    }
    
    func error(err: String) {
        self.reject?("E_SDK_ERROR", err, nil)
        self.cleanup()
    }
    
    private func cleanup() {
        self.resolve = nil
        self.reject = nil
    }
}
