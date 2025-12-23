import Foundation
import MiVIPSdk
import MiVIPApi
import React

@objc(MiVIPModule)
class MiVIPModule: NSObject, RequestStatusDelegate {
    
    private var mivipHub: MiVIPHub?
    private var resolve: RCTPromiseResolveBlock?
    private var reject: RCTPromiseRejectBlock?
    private var initError: String?
    
    override init() {
        super.init()
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        print("MiVIPModule: Current Bundle ID: \(bundleId)")
        do {
            self.mivipHub = try MiVIPHub()
            configureHub()
            print("MiVIPModule: SDK successfully initialized")
        } catch {
            self.initError = error.localizedDescription
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
        hub.setFontNameRegular(fontName: "WorkSans-Regular")
    }
    
    @objc(startRequest:resolver:rejecter:)
    func startRequest(id: String, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        self.resolve = resolver
        self.reject = rejecter
        
        DispatchQueue.main.async {
            guard let hub = self.mivipHub else {
                let msg = self.initError ?? "SDK not initialized. Check license key in Info.plist."
                rejecter("E_INIT_FAILED", msg, nil)
                return
            }
            
            guard let topVC = self.getTopViewController() else {
                rejecter("E_VC_FAILED", "Could not find valid screen to present SDK", nil)
                return
            }
            
            print("MiVIPModule: Starting request \(id) on \(type(of: topVC))")
            hub.request(vc: topVC, miVipRequestId: id, requestStatusDelegate: self)
        }
    }
    
    @objc(scanQRCode:rejecter:)
    func scanQRCode(resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            guard let topVC = self.getTopViewController() else {
                rejecter("E_VC_FAILED", "Could not find valid screen to present scanner", nil)
                return
            }
            
            let scanner = CustomQRScannerViewController()
            scanner.onCodeScanned = { [weak self, weak scanner] code in
                scanner?.dismiss(animated: true) {
                    if let uuid = self?.extractUUID(from: code) {
                        print("MiVIPModule: Extracted UUID from QR: \(uuid)")
                        self?.startRequest(id: uuid, resolver: resolver, rejecter: rejecter)
                    } else {
                        rejecter("E_INVALID_QR", "Invalid QR: No Request ID found", nil)
                    }
                }
            }
            topVC.present(scanner, animated: true)
        }
    }
    
    // MARK: - UI Helpers
    
    private func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?.windows
            .filter { $0.isKeyWindow }.first
        
        var topController = keyWindow?.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }
        return topController
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
            print("MiVIPModule: Success - \(result)")
            self.resolve?(String(describing: result))
            self.cleanup()
        }
    }
    
    func error(err: String) {
        print("MiVIPModule: Error - \(err)")
        self.reject?("E_SDK_ERROR", err, nil)
        self.cleanup()
    }
    
    private func cleanup() {
        self.resolve = nil
        self.reject = nil
    }
}
