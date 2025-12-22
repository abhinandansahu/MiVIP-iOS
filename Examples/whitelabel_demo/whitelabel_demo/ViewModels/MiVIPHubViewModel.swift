import Foundation
import UIKit
import Combine
import MiVIPSdk
import MiVIPApi

class MiVIPHubViewModel: NSObject {
    @Published var requestState: MiVIPRequestState = .idle
    
    private let mivipService: MiVIPServiceProtocol
    private var activeTask: Task<Void, Never>?

    init(mivipService: MiVIPServiceProtocol) {
        self.mivipService = mivipService
        super.init()
    }
    
    deinit {
        activeTask?.cancel()
    }

    func startQRCodeScan(from vc: UIViewController, callbackURL: String?) {
        requestState = .loading
        mivipService.startQRCodeScan(vc: vc, delegate: self, callbackURL: callbackURL)
    }
    
    func openRequest(from vc: UIViewController, id: String, callbackURL: String?) {
        guard !id.isEmpty else {
            requestState = .failure(.validation("Request ID cannot be empty"))
            return
        }
        requestState = .loading
        mivipService.openRequest(vc: vc, id: id, delegate: self, callbackURL: callbackURL)
    }
    
    func openRequestByCode(from vc: UIViewController, code: String, callbackURL: String?) {
        guard !code.isEmpty else {
            requestState = .failure(.validation("Request code cannot be empty"))
            return
        }
        requestState = .loading
        
        activeTask?.cancel()
        activeTask = Task { @MainActor in
            do {
                if let idRequest = try await mivipService.getRequestId(from: code) {
                    guard !Task.isCancelled else { return }
                    self.mivipService.openRequest(vc: vc, id: idRequest, delegate: self, callbackURL: callbackURL)
                } else {
                    guard !Task.isCancelled else { return }
                    self.requestState = .failure(.sdk("Failed to get request ID from code"))
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.requestState = .failure(.sdk(error.localizedDescription))
            }
        }
    }
    
    func showHistory(from vc: UIViewController) {
        mivipService.showHistory(vc: vc)
    }
    
    func showAccount(from vc: UIViewController) {
        mivipService.showAccount(vc: vc)
    }
}

extension MiVIPHubViewModel: RequestStatusDelegate {
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        DispatchQueue.main.async {
            if let result = result {
                self.requestState = .success(result)
            } else {
                self.requestState = .idle
            }
        }
    }
    
    func error(err: String) {
        DispatchQueue.main.async {
            self.requestState = .failure(.sdk(err))
        }
    }
}
