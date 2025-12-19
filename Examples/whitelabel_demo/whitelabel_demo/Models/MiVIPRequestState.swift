import Foundation
import MiVIPApi

enum MiVIPRequestState {
    case idle
    case loading
    case success(MiVIPApi.RequestResult)
    case failure(MiVIPError)
}
