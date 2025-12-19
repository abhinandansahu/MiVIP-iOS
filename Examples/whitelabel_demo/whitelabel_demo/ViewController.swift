//
//  ViewController.swift
//  whitelabel_demo
//

import UIKit
import MiVIPSdk
import MiVIPApi

class ViewController: UIViewController {
    
    private var requestIdTextField = UITextField()
    private var documentCallbackTextField = UITextField()
    private var requestCodeTextField = UITextField()

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        
        var y = 100.0
        addCallbackTextField(y: y)
        y += 70
        addButton(scope: "QR", y: y)
        y += 65
        addRequestTextField(y: y)
        y += 50
        addButton(scope: "request", y: y)
        y += 65
        addRequestCodeTextField(y: y)
        y += 50
        addButton(scope: "code", y: y)
        y += 65
        addButton(scope: "history", y: y)
        y += 65
        addButton(scope: "account", y: y)
    }
    
    @objc fileprivate func buttonAction(_ sender: UIButton) {
        guard let scope = sender.accessibilityIdentifier else { return }
        
        do {
            let mivip = try MiVIPHub()
            mivip.setSoundsDisabled(true)
            mivip.setReusableEnabled(false)
            mivip.setLogDisabled(false)
            
            mivip.setFontNameUltraLight(fontName: "WorkSans-ExtraLight")
            mivip.setFontNameLight(fontName: "WorkSans-Light")
            mivip.setFontNameThin(fontName: "WorkSans-Thin")
            mivip.setFontNameBlack(fontName: "WorkSans-Black")
            mivip.setFontNameMedium(fontName: "WorkSans-Medium")
            mivip.setFontNameRegular(fontName: "WorkSans-Regular")
            mivip.setFontNameSemiBold(fontName: "WorkSans-SemiBold")
            mivip.setFontNameBold(fontName: "WorkSans-Bold")
            mivip.setFontNamHeavy(fontName: "WorkSans-ExtraBold")
            
            switch scope {
            case "QR":
                mivip.qrCode(vc: self, requestStatusDelegate: self, documentCallbackUrl: documentCallbackTextField.text)
            case "history":
                mivip.history(vc: self)
            case "account":
                mivip.account(vc: self)
            case "request":
                guard let idRequest = requestIdTextField.text, !idRequest.isEmpty else {
                    showError(message: "Please enter a valid request ID", title: "Input Required")
                    return
                }
                mivip.request(vc: self, miVipRequestId: idRequest, requestStatusDelegate: self, documentCallbackUrl: documentCallbackTextField.text)
            case "code":
                guard let code = requestCodeTextField.text, !code.isEmpty else {
                    showError(message: "Please enter a 4-digit request code", title: "Input Required")
                    return
                }
                mivip.getRequestIdFromCode(code: code) { (idRequest, error) in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        if let idRequest = idRequest {
                            mivip.request(vc: strongSelf, miVipRequestId: idRequest, requestStatusDelegate: strongSelf, documentCallbackUrl: strongSelf.documentCallbackTextField.text)
                        }
                        if let error = error {
                            strongSelf.showError(message: "Could not find request for code \(code): \(error)", title: "Not Found")
                        }
                    }
                }
            default:
                break
            }
            
        } catch let error as MiVIPHub.LicenseError {
            showError(error, title: "License Error")
        } catch {
            showError(error)
        }
    }
    
    private func showError(_ error: Error, title: String = "Error") {
        let message: String
        if let licenseError = error as? MiVIPHub.LicenseError {
            message = "License error: \(licenseError.rawValue). Please contact support."
        } else {
            message = error.localizedDescription
        }
        showError(message: message, title: title)
    }

    private func showError(message: String, title: String = "Error") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: MiVIPSdk.RequestStatusDelegate {
    
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        debugPrint("MiVIP: RequestStatus = \(String(describing: status)), RequestResult \(String(describing: result)), ScoreResponse \(String(describing: scoreResponse)), MiVIPRequest \(String(describing: request))")
    }
    
    func error(err: String) {
        debugPrint("MiVIP: \(err)")
        DispatchQueue.main.async { [weak self] in
            self?.showError(message: err, title: "SDK Error")
        }
    }
}

extension ViewController {
    private func addButton(scope: String, y: CGFloat) {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60)
        button.backgroundColor = .systemGray4
        button.setTitle(scope.uppercased(), for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 8
        
        button.accessibilityIdentifier = scope
        button.accessibilityLabel = getAccessibilityLabel(for: scope)
        button.accessibilityHint = getAccessibilityHint(for: scope)
        
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.view.addSubview(button)
    }
    
    private func getAccessibilityLabel(for scope: String) -> String {
        switch scope {
        case "QR": return "Scan QR Code"
        case "request": return "Open Request by ID"
        case "code": return "Open Request by Code"
        case "history": return "View Request History"
        case "account": return "View Account and Wallet"
        default: return scope
        }
    }

    private func getAccessibilityHint(for scope: String) -> String {
        switch scope {
        case "QR": return "Starts camera to scan a verification request QR code"
        case "request": return "Opens a specific verification request using the ID above"
        case "code": return "Opens a verification request using the 4-digit code above"
        case "history": return "Shows all your previous verification requests"
        case "account": return "Shows your stored identity information and wallet"
        default: return "Tap to activate"
        }
    }
    
    private func addRequestTextField(y: CGFloat) {
        requestIdTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
        requestIdTextField.backgroundColor = .systemBackground
        requestIdTextField.textColor = .label
        requestIdTextField.textAlignment = .center
        requestIdTextField.borderStyle = .roundedRect
        requestIdTextField.attributedPlaceholder = NSAttributedString(string: "request ID to open", attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText])
        
        requestIdTextField.accessibilityLabel = "Request ID"
        requestIdTextField.accessibilityHint = "Enter the verification request ID to open directly"
        
        requestIdTextField.font = UIFont.preferredFont(forTextStyle: .body)
        requestIdTextField.adjustsFontForContentSizeCategory = true
        
        self.view.addSubview(requestIdTextField)
    }
    
    private func addCallbackTextField(y: CGFloat) {
        documentCallbackTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
        documentCallbackTextField.backgroundColor = .systemBackground
        documentCallbackTextField.textColor = .label
        documentCallbackTextField.textAlignment = .center
        documentCallbackTextField.borderStyle = .roundedRect
        documentCallbackTextField.attributedPlaceholder = NSAttributedString(string: "document callback URL", attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText])
        
        documentCallbackTextField.accessibilityLabel = "Document Callback URL"
        documentCallbackTextField.accessibilityHint = "Enter a URL to receive document verification updates"
        
        documentCallbackTextField.font = UIFont.preferredFont(forTextStyle: .body)
        documentCallbackTextField.adjustsFontForContentSizeCategory = true
        
        self.view.addSubview(documentCallbackTextField)
    }
    
    private func addRequestCodeTextField(y: CGFloat) {
        requestCodeTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
        requestCodeTextField.backgroundColor = .systemBackground
        requestCodeTextField.textColor = .label
        requestCodeTextField.textAlignment = .center
        requestCodeTextField.borderStyle = .roundedRect
        requestCodeTextField.keyboardType = .numberPad
        requestCodeTextField.attributedPlaceholder = NSAttributedString(string: "4 digit request code", attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText])
        
        requestCodeTextField.accessibilityLabel = "Request Code"
        requestCodeTextField.accessibilityHint = "Enter the 4-digit code to open a verification request"
        
        requestCodeTextField.font = UIFont.preferredFont(forTextStyle: .body)
        requestCodeTextField.adjustsFontForContentSizeCategory = true
        
        self.view.addSubview(requestCodeTextField)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
