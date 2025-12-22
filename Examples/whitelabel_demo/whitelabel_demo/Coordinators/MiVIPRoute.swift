import Foundation

enum MiVIPRoute {
    case main
    case qrScanner(callbackURL: String?)
    case request(id: String, callbackURL: String?)
    case requestByCode(code: String, callbackURL: String?)
    case history
    case account
}
