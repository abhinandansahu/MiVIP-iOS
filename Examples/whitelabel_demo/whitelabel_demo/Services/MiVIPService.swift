import Foundation
import UIKit
import MiVIPSdk
import MiVIPApi

protocol MiVIPServiceProtocol {
    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?)
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?)
    func openRequestByCode(vc: UIViewController, code: String, delegate: RequestStatusDelegate, callbackURL: String?, completion: @escaping (String?, Error?) -> Void)
    func getRequestId(from code: String) async throws -> String?
    func showHistory(vc: UIViewController)
    func showAccount(vc: UIViewController)
}

class MiVIPService: MiVIPServiceProtocol {
    private let mivipHub: MiVIPHub

    init() throws {
        self.mivipHub = try MiVIPHub()
        configureHub()
    }

    private func configureHub() {
        mivipHub.setSoundsDisabled(true)
        mivipHub.setReusableEnabled(false)
        mivipHub.setLogDisabled(false)
        configureFonts()
    }

    private func configureFonts() {
        mivipHub.setFontNameUltraLight(fontName: "WorkSans-ExtraLight")
        mivipHub.setFontNameLight(fontName: "WorkSans-Light")
        mivipHub.setFontNameThin(fontName: "WorkSans-Thin")
        mivipHub.setFontNameBlack(fontName: "WorkSans-Black")
        mivipHub.setFontNameMedium(fontName: "WorkSans-Medium")
        mivipHub.setFontNameRegular(fontName: "WorkSans-Regular")
        mivipHub.setFontNameSemiBold(fontName: "WorkSans-SemiBold")
        mivipHub.setFontNameBold(fontName: "WorkSans-Bold")
        mivipHub.setFontNamHeavy(fontName: "WorkSans-ExtraBold")
    }

    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?) {
        mivipHub.qrCode(vc: vc, requestStatusDelegate: delegate, documentCallbackUrl: callbackURL)
    }

    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) {
        mivipHub.request(vc: vc, miVipRequestId: id, requestStatusDelegate: delegate, documentCallbackUrl: callbackURL)
    }

    func openRequestByCode(vc: UIViewController, code: String, delegate: RequestStatusDelegate, callbackURL: String?, completion: @escaping (String?, Error?) -> Void) {
        mivipHub.getRequestIdFromCode(code: code, completion: completion)
    }

    func getRequestId(from code: String) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            mivipHub.getRequestIdFromCode(code: code) { id, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: id)
                }
            }
        }
    }

    func showHistory(vc: UIViewController) {
        mivipHub.history(vc: vc)
    }

    func showAccount(vc: UIViewController) {
        mivipHub.account(vc: vc)
    }
}
