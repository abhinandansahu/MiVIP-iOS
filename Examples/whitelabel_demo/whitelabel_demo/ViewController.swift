//
//  ViewController.swift
//  whitelabel_demo
//

import UIKit
import Combine
import MiVIPSdk
import MiVIPApi

class ViewController: UIViewController {
    private var viewModel: MiVIPHubViewModel!
    private weak var coordinator: MiVIPCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: MiVIPHubViewModel, coordinator: MiVIPCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    
    private let requestIdTextField = UITextField()
    private let documentCallbackTextField = UITextField()
    private let requestCodeTextField = UITextField()
    
    private let loadingView = LoadingView()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        hideKeyboardWhenTappedAround()
    }
    
    deinit {
        view.gestureRecognizers?.forEach { $0.removeTarget(nil, action: nil) }
        view.subviews.forEach { subview in
            subview.gestureRecognizers?.forEach { gesture in
                gesture.removeTarget(nil, action: nil)
            }
        }
        print("ViewController deallocated - no memory leak")
    }
    
    private func setupViewModel() {
    }
    
    private func setupUI() {
        view.backgroundColor = ColorPalette.background
        title = "MiVIP Demo"
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
        ])
        
        configureTextFields()
        
        stackView.addArrangedSubview(documentCallbackTextField)
        stackView.addArrangedSubview(createButton(title: "Scan QR Code", identifier: "QR"))
        
        stackView.addArrangedSubview(createSectionSpacer())
        
        stackView.addArrangedSubview(requestIdTextField)
        stackView.addArrangedSubview(createButton(title: "Open Request by ID", identifier: "request"))
        
        stackView.addArrangedSubview(createSectionSpacer())
        
        stackView.addArrangedSubview(requestCodeTextField)
        stackView.addArrangedSubview(createButton(title: "Open Request by Code", identifier: "code"))
        
        stackView.addArrangedSubview(createSectionSpacer())
        
        stackView.addArrangedSubview(createButton(title: "View Request History", identifier: "history"))
        stackView.addArrangedSubview(createButton(title: "View Account and Wallet", identifier: "account"))
    }
    
    private func configureTextFields() {
        [documentCallbackTextField, requestIdTextField, requestCodeTextField].forEach { tf in
            tf.backgroundColor = ColorPalette.secondaryBackground
            tf.textColor = ColorPalette.text
            tf.textAlignment = .center
            tf.borderStyle = .roundedRect
            tf.font = UIFont.preferredFont(forTextStyle: .body)
            tf.adjustsFontForContentSizeCategory = true
            tf.translatesAutoresizingMaskIntoConstraints = false
            tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        }
        
        documentCallbackTextField.placeholder = "document callback URL"
        documentCallbackTextField.accessibilityLabel = "Document Callback URL"
        documentCallbackTextField.accessibilityHint = "Enter a URL to receive document verification updates"
        
        requestIdTextField.placeholder = "request ID to open"
        requestIdTextField.accessibilityLabel = "Request ID"
        requestIdTextField.accessibilityHint = "Enter the verification request ID to open directly"
        
        requestCodeTextField.placeholder = "4 digit request code"
        requestCodeTextField.accessibilityLabel = "Request Code"
        requestCodeTextField.accessibilityHint = "Enter the 4-digit code to open a verification request"
        requestCodeTextField.keyboardType = .numberPad
    }
    
    private func createButton(title: String, identifier: String) -> PrimaryButton {
        let button = PrimaryButton(type: .system)
        button.setTitle(title.uppercased(), for: .normal)
        button.accessibilityIdentifier = identifier
        button.accessibilityLabel = title
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        return button
    }
    
    private func createSectionSpacer() -> UIView {
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.heightAnchor.constraint(equalToConstant: 10).isActive = true
        return spacer
    }
    
    @objc private func buttonAction(_ sender: UIButton) {
        impactFeedback.impactOccurred()
        guard let scope = sender.accessibilityIdentifier, let viewModel = viewModel else { return }
        
        switch scope {
        case "QR":
            coordinator?.showQRScanner(from: self, viewModel: viewModel, callbackURL: documentCallbackTextField.text)
        case "request":
            coordinator?.showRequest(from: self, viewModel: viewModel, id: requestIdTextField.text ?? "", callbackURL: documentCallbackTextField.text)
        case "code":
            coordinator?.showRequestByCode(from: self, viewModel: viewModel, code: requestCodeTextField.text ?? "", callbackURL: documentCallbackTextField.text)
        case "history":
            coordinator?.showHistory(from: self, viewModel: viewModel)
        case "account":
            coordinator?.showAccount(from: self, viewModel: viewModel)
        default:
            break
        }
    }
    
    private func bindViewModel() {
        viewModel.$requestState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func handleStateChange(_ state: MiVIPRequestState) {
        switch state {
        case .idle:
            loadingView.hide()
            view.isUserInteractionEnabled = true
        case .loading:
            loadingView.show(in: view)
            view.isUserInteractionEnabled = false
            notifyAccessibilityStatusChange("Loading verification request...")
        case .success(let result):
            loadingView.hide()
            view.isUserInteractionEnabled = true
            notificationFeedback.notificationOccurred(.success)
            notifyAccessibilityStatusChange("Verification completed successfully")
            debugPrint("MiVIP: Success with result \(result)")
        case .failure(let error):
            loadingView.hide()
            view.isUserInteractionEnabled = true
            notificationFeedback.notificationOccurred(.error)
            handleError(error)
        }
    }
    
    private func notifyAccessibilityStatusChange(_ status: String) {
        UIAccessibility.post(notification: .announcement, argument: status)
    }
    
    override var accessibilityCustomActions: [UIAccessibilityCustomAction]? {
        get {
            [
                UIAccessibilityCustomAction(name: "Clear all fields") { [weak self] _ in
                    self?.requestIdTextField.text = ""
                    self?.documentCallbackTextField.text = ""
                    self?.requestCodeTextField.text = ""
                    return true
                }
            ]
        }
        set { }
    }
    
    private func handleError(_ error: Error) {
        let message: String
        let title: String = "Error"
        
        if let mivipError = error as? MiVIPError {
            message = mivipError.userMessage
        } else if let licenseError = error as? MiVIPHub.LicenseError {
            message = "License error: \(licenseError.rawValue). Please contact support."
        } else {
            message = error.localizedDescription
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

private class WeakRequestStatusDelegate: MiVIPSdk.RequestStatusDelegate {
    weak var target: RequestStatusDelegate?

    init(target: RequestStatusDelegate) {
        self.target = target
    }

    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        target?.status(status: status, result: result, scoreResponse: scoreResponse, request: request)
    }

    func error(err: String) {
        target?.error(err: err)
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
