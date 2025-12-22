import Foundation
import UIKit
import Combine
import MiVIPSdk
import MiVIPApi

class MiVIPHubViewModel: NSObject {
    @Published var requestState: MiVIPRequestState = .idle
    
    override init() {
        super.init()
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
