import UIKit
import Combine
import MiVIPSdk
import MiVIPApi
import MiSnapCore
import AVFoundation

// MARK: - Models & State

enum MiVIPRequestState {
    case idle, loading, success(MiVIPApi.RequestResult), failure(MiVIPError)
}

enum MiVIPError: Error {
    case sdk(String), validation(String), license(String)
    var userMessage: String {
        switch self {
        case .sdk(let msg): return "Error: \(msg)"
        case .validation(let msg): return msg
        case .license(let msg): return "License Error: \(msg)"
        }
    }
}

typealias RequestStatusDelegate = MiVIPSdk.RequestStatusDelegate

// MARK: - Theming

struct ColorPalette {
    // Mitek Branding Colors
    static let mitekRed = UIColor(hex: "#EE2C46")
    static let mitekBlue = UIColor(hex: "#0B1B2B")
    static let mitekOrange = UIColor(hex: "#E84915")
    static let mitekYellow = UIColor(hex: "#F6A832")

    static let primaryButton = mitekRed
    static let accent = mitekRed
    static let disabledButton = UIColor.systemGray4
    static let background = UIColor.systemBackground
    static let secondaryBackground = UIColor.secondarySystemBackground
    static let text = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
}

extension UIColor {
    convenience init(hex: String) {
        var cString: String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cString.hasPrefix("#") { cString.remove(at: cString.startIndex) }
        if (cString.count) != 6 { self.init(white: 0.5, alpha: 1.0); return }
        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        self.init(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

// MARK: - Protocols

protocol MiVIPServiceProtocol {
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?)
}

// MARK: - Dependency Injection

class DependencyContainer {
    static let shared = DependencyContainer()
    let mivipService: MiVIPServiceProtocol
    let initializationError: Error?
    
    init() {
        do {
            self.mivipService = try MiVIPService()
            self.initializationError = nil
        } catch {
            self.mivipService = MiVIPServiceFallback(error: error)
            self.initializationError = error
        }
    }
    
    func makeMiVIPHubViewModel() -> MiVIPHubViewModel { MiVIPHubViewModel() }
}

// MARK: - Navigation (MVVM-C)

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    func start()
}

protocol Router: AnyObject {
    var navigationController: UINavigationController { get }
    func setRootViewController(_ viewController: UIViewController, animated: Bool)
}

class AppRouter: Router {
    let navigationController = UINavigationController()
    func setRootViewController(_ viewController: UIViewController, animated: Bool) {
        navigationController.setViewControllers([viewController], animated: animated)
    }
}

class AppCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let window: UIWindow
    private let container: DependencyContainer
    private let router = AppRouter()

    init(window: UIWindow, container: DependencyContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        window.rootViewController = router.navigationController
        window.makeKeyAndVisible()
        let coord = MiVIPCoordinator(router: router, container: container)
        childCoordinators.append(coord)
        coord.start()
    }
}

class MiVIPCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let router: Router
    private let container: DependencyContainer
    private var viewModel: MiVIPHubViewModel?

    init(router: Router, container: DependencyContainer) {
        self.router = router
        self.container = container
    }

    func start() {
        let vm = container.makeMiVIPHubViewModel()
        self.viewModel = vm
        let vc = ViewController(viewModel: vm, coordinator: self, initializationError: container.initializationError)
        router.setRootViewController(vc, animated: true)
    }

    func coordinate(to route: MiVIPRoute) {
        guard let vm = viewModel else { return }
        switch route {
        case .qr:
            let scanner = CustomQRScannerViewController()
            scanner.onCodeScanned = { [weak self, weak scanner] code in
                scanner?.dismiss(animated: true) {
                    if let uuid = self?.extractUUID(from: code) {
                        self?.coordinate(to: .request(id: uuid))
                    } else {
                        self?.viewModel?.requestState = .failure(.validation("No Request ID found in QR."))
                    }
                }
            }
            router.navigationController.present(scanner, animated: true)
            
        case .request(let id):
            vm.requestState = .loading
            container.mivipService.openRequest(vc: router.navigationController, id: id, delegate: vm, callbackURL: nil)
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
}

enum MiVIPRoute {
    case qr
    case request(id: String)
}

// MARK: - View Model

class MiVIPHubViewModel: NSObject, RequestStatusDelegate {
    @Published var requestState: MiVIPRequestState = .idle
    
    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        if let result = result { self.requestState = .success(result) }
        else { self.requestState = .idle }
    }
    
    func error(err: String) { self.requestState = .failure(.sdk(err)) }
}

// MARK: - Services

class MiVIPService: MiVIPServiceProtocol {
    private let mivipHub: MiVIPHub
    init() throws {
        self.mivipHub = try MiVIPHub()
        configureHub()
    }
    
    private func configureHub() {
        mivipHub.setSoundsDisabled(true)
        mivipHub.setReusableEnabled(false)
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
    
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) {
        mivipHub.request(vc: vc, miVipRequestId: id, requestStatusDelegate: delegate, documentCallbackUrl: callbackURL)
    }
}

class MiVIPServiceFallback: MiVIPServiceProtocol {
    let error: Error
    init(error: Error) { self.error = error }
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) {
        let alert = UIAlertController(title: "SDK Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}

// MARK: - UI Components

class PrimaryButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    private func setupUI() {
        layer.cornerRadius = 12
        titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel?.adjustsFontForContentSizeCategory = true
        addTarget(self, action: #selector(touchDown), for: .touchDown)
        addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        updateColors()
    }
    private func updateColors() {
        backgroundColor = isEnabled ? ColorPalette.primaryButton : ColorPalette.disabledButton
        setTitleColor(.white, for: .normal)
    }
    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) { self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95) }
    }
    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) { self.transform = .identity }
    }
    override var isEnabled: Bool { didSet { updateColors() } }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColors()
    }
}

class OptionCardView: UIView {
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    let actionButton = PrimaryButton()
    var textField: UITextField?
    
    init(icon: UIImage?, title: String, description: String, buttonTitle: String, includeTextField: Bool = false) {
        super.init(frame: .zero)
        setupCard(icon: icon, title: title, description: description, buttonTitle: buttonTitle, includeTextField: includeTextField)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupCard(icon: UIImage?, title: String, description: String, buttonTitle: String, includeTextField: Bool) {
        backgroundColor = ColorPalette.secondaryBackground
        layer.cornerRadius = 16
        
        let iconView = UIImageView(image: icon)
        iconView.tintColor = ColorPalette.accent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.text = title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.textColor = ColorPalette.text
        
        let headerStack = UIStackView(arrangedSubviews: [iconView, titleLabel])
        headerStack.spacing = 12
        
        descriptionLabel.text = description
        descriptionLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        descriptionLabel.textColor = ColorPalette.secondaryText
        descriptionLabel.numberOfLines = 0
        
        actionButton.setTitle(buttonTitle, for: .normal)
        
        let stack = UIStackView(arrangedSubviews: [headerStack, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = 16
        
        if includeTextField {
            let tf = UITextField()
            tf.borderStyle = .roundedRect
            tf.placeholder = "Enter ID"
            tf.autocapitalizationType = .none
            tf.autocorrectionType = .no
            tf.backgroundColor = .systemBackground
            self.textField = tf
            stack.addArrangedSubview(tf)
        }
        
        stack.addArrangedSubview(actionButton)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),
            actionButton.heightAnchor.constraint(equalToConstant: 50),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
}

class ErrorBannerView: UIView {
    private let messageLabel = UILabel()
    var onDismiss: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemRed.cgColor
        
        messageLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        messageLabel.textColor = .systemRed
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(messageLabel)
        
        let dismiss = UIButton(type: .close)
        dismiss.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
        dismiss.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dismiss)
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            dismiss.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            dismiss.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: dismiss.leadingAnchor, constant: -8)
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    func setMessage(_ m: String) { messageLabel.text = m }
    @objc private func dismissTapped() { onDismiss?() }
}

// MARK: - Custom QR Scanner

class CustomQRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCodeScanned: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupScanner()
    }
    
    private func setupScanner() {
        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [.qr]
        }
        
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        self.captureSession = session
        
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.tintColor = .white
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cancel)
        NSLayoutConstraint.activate([
            cancel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20)
        ])
        
        DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
    }
    
    @objc private func cancelTapped() { dismiss(animated: true) }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
           let stringValue = metadataObject.stringValue {
            captureSession?.stopRunning()
            onCodeScanned?(stringValue)
        }
    }
}

// MARK: - Main View Controller

class ViewController: UIViewController {
    private let viewModel: MiVIPHubViewModel
    private let coordinator: MiVIPCoordinator
    private let initializationError: Error?
    private var cancellables = Set<AnyCancellable>()
    
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private var qrCard: OptionCardView!
    private var requestIdCard: OptionCardView!
    private let loading = UIActivityIndicatorView(style: .large)
    private var errorBanner: ErrorBannerView?

    init(viewModel: MiVIPHubViewModel, coordinator: MiVIPCoordinator, initializationError: Error?) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        self.initializationError = initializationError
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupKeyboardNotifications()
        if let err = initializationError { showError(err.localizedDescription) }
    }

    private func setupUI() {
        view.backgroundColor = ColorPalette.background
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        
        let logo = UIImageView(image: UIImage(named: "my_logo"))
        logo.contentMode = .scaleAspectFit
        logo.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Identity Verification"
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = ColorPalette.mitekRed
        titleLabel.textAlignment = .center
        
        qrCard = OptionCardView(icon: UIImage(systemName: "camera.viewfinder"), title: "Scan QR Code", description: "Scan the QR code from your email.", buttonTitle: "Scan QR")
        qrCard.actionButton.addTarget(self, action: #selector(qrAction), for: .touchUpInside)
        
        let divider = UILabel()
        divider.text = "— OR —"
        divider.textAlignment = .center
        divider.textColor = ColorPalette.secondaryText
        
        requestIdCard = OptionCardView(icon: UIImage(systemName: "key.fill"), title: "Enter Request ID", description: "Manually enter your Request ID.", buttonTitle: "Continue", includeTextField: true)
        requestIdCard.actionButton.isEnabled = false
        requestIdCard.actionButton.addTarget(self, action: #selector(requestIdAction), for: .touchUpInside)
        requestIdCard.textField?.addTarget(self, action: #selector(validateInput), for: .editingChanged)
        requestIdCard.textField?.delegate = self
        
        contentStack.addArrangedSubview(logo)
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(qrCard)
        contentStack.addArrangedSubview(divider)
        contentStack.addArrangedSubview(requestIdCard)
        
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
            loading.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loading.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }

    private func setupBindings() {
        viewModel.$requestState.receive(on: RunLoop.main).sink { [weak self] state in
            switch state {
            case .loading: self?.loading.startAnimating()
            case .success(let res):
                self?.loading.stopAnimating()
                self?.alert("Success", "Verification Result: \(res)")
            case .failure(let err):
                self?.loading.stopAnimating()
                self?.showError(err.userMessage)
            default: self?.loading.stopAnimating()
            }
        }.store(in: &cancellables)
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        
        if let activeField = requestIdCard.textField {
            let rect = activeField.convert(activeField.bounds, to: scrollView)
            scrollView.scrollRectToVisible(rect, animated: true)
        }
    }
    
    @objc private func keyboardWillHide() {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets = .zero
    }

    private func showError(_ m: String) {
        errorBanner?.removeFromSuperview()
        let banner = ErrorBannerView()
        banner.setMessage(m)
        banner.onDismiss = { [weak self] in self?.errorBanner?.removeFromSuperview() }
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        self.errorBanner = banner
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func alert(_ t: String, _ m: String) {
        let a = UIAlertController(title: t, message: m, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
    
    @objc private func validateInput() {
        let text = requestIdCard.textField?.text ?? ""
        requestIdCard.actionButton.isEnabled = UUID(uuidString: text) != nil
    }
    @objc private func qrAction() { coordinator.coordinate(to: .qr) }
    @objc private func requestIdAction() { 
        if let id = requestIdCard.textField?.text { coordinator.coordinate(to: .request(id: id)) }
    }
    @objc private func dismissKeyboard() { view.endEditing(true) }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if requestIdCard.actionButton.isEnabled { requestIdAction() }
        return true
    }
}
