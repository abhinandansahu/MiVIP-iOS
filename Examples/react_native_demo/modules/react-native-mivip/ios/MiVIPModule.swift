import Foundation
import MiVIPSdk
import MiVIPApi
import MiSnapCore
import React

// MARK: - Supporting Types

private struct PendingRequest {
    let resolve: RCTPromiseResolveBlock
    let reject: RCTPromiseRejectBlock
    let timestamp: Date
}

@objc(MiVIPModule)
class MiVIPModule: NSObject, RequestStatusDelegate {

    // MARK: - Properties

    private var mivipHub: MiVIPHub?
    private var initError: String?

    // Thread-safe request tracking (fixes Issue #4: Race condition)
    private var pendingRequests: [String: PendingRequest] = [:]
    private let requestQueue = DispatchQueue(label: "com.mitek.mivip.requests", attributes: .concurrent)

    // Timeout management (fixes Issue #1: Memory leak)
    private var requestTimers: [String: Timer] = [:]
    private let timeoutInterval: TimeInterval = 60
    
    override init() {
        super.init()
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"
        print("MiVIPModule: Current Bundle ID: \(bundleId)")
        
        // BASIC SOLUTION: 
        // 1. You can hardcode the license key in Info.plist under MISNAP_LICENSE_KEY (easiest).
        // 2. OR you can set it programmatically here:
        // MiSnapLicenseManager.shared.setLicenseKey("YOUR_LICENSE_KEY_HERE")
        
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
        // Normalize and validate UUID (fixes Issue #10)
        let normalizedId = id.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard UUID(uuidString: normalizedId) != nil else {
            rejecter("E_INVALID_UUID", "Invalid request ID format: \(id)", nil)
            return
        }

        // Check for duplicate request
        requestQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            if self.pendingRequests[normalizedId] != nil {
                DispatchQueue.main.async {
                    rejecter("E_REQUEST_IN_PROGRESS", "Request \(normalizedId) is already in progress", nil)
                }
                return
            }

            // Store request callbacks
            self.pendingRequests[normalizedId] = PendingRequest(
                resolve: resolver,
                reject: rejecter,
                timestamp: Date()
            )

            // Start timeout timer on main thread
            DispatchQueue.main.async {
                self.startTimeoutTimer(for: normalizedId)
            }
        }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            guard let hub = self.mivipHub else {
                let msg = self.initError ?? "SDK not initialized. Check license key in Info.plist."
                self.rejectRequest(id: normalizedId, code: "E_INIT_FAILED", message: msg)
                return
            }

            guard let topVC = self.getTopViewController() else {
                self.rejectRequest(id: normalizedId, code: "E_VC_FAILED", message: "Could not find valid screen to present SDK")
                return
            }

            print("MiVIPModule: Starting request \(normalizedId) on \(type(of: topVC))")
            hub.request(vc: topVC, miVipRequestId: normalizedId, requestStatusDelegate: self)
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
    
    // MARK: - UUID Validation (fixes Issue #10)

    private func extractUUID(from string: String) -> String? {
        // Normalize input
        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // Try direct UUID parsing first
        if let uuid = UUID(uuidString: normalized) {
            return uuid.uuidString.lowercased()
        }

        // Extract from URL or longer string using regex
        let pattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(normalized.startIndex..., in: normalized)
        if let match = regex.firstMatch(in: normalized, range: range),
           let r = Range(match.range, in: normalized) {
            let candidate = String(normalized[r])

            // CRITICAL: Validate extracted string is actually a valid UUID
            if UUID(uuidString: candidate) != nil {
                return candidate.lowercased()
            }
        }

        return nil
    }
    
    // MARK: - RequestStatusDelegate

    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        guard let request = request, let requestId = request.id else {
            print("MiVIPModule: Received status without request ID")
            return
        }

        if let result = result {
            print("MiVIPModule: Success for request \(requestId) - \(result)")
            resolveRequest(id: requestId.uuidString, result: String(describing: result))
        }
    }

    func error(err: String) {
        print("MiVIPModule: SDK Error - \(err)")

        // SDK doesn't provide request context, so reject all pending requests
        requestQueue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            let pendingIds = Array(self.pendingRequests.keys)
            for id in pendingIds {
                self.rejectRequest(id: id, code: "E_SDK_ERROR", message: err)
            }
        }
    }

    // MARK: - Request Management

    private func startTimeoutTimer(for requestId: String) {
        // Invalidate existing timer if any
        requestTimers[requestId]?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            print("MiVIPModule: Request \(requestId) timed out after \(Int(self.timeoutInterval))s")
            self.rejectRequest(
                id: requestId,
                code: "E_TIMEOUT",
                message: "Request timed out after \(Int(self.timeoutInterval)) seconds"
            )
        }

        requestTimers[requestId] = timer
    }

    private func resolveRequest(id: String, result: String) {
        requestQueue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let request = self.pendingRequests[id] else { return }

            DispatchQueue.main.async {
                // Clean up timer
                self.requestTimers[id]?.invalidate()
                self.requestTimers.removeValue(forKey: id)

                // Resolve promise
                request.resolve(result)
            }

            // Remove from pending requests
            self.pendingRequests.removeValue(forKey: id)
        }
    }

    private func rejectRequest(id: String, code: String, message: String) {
        requestQueue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let request = self.pendingRequests[id] else { return }

            DispatchQueue.main.async {
                // Clean up timer
                self.requestTimers[id]?.invalidate()
                self.requestTimers.removeValue(forKey: id)

                // Reject promise
                request.reject(code, message, nil)
            }

            // Remove from pending requests
            self.pendingRequests.removeValue(forKey: id)
        }
    }
}
