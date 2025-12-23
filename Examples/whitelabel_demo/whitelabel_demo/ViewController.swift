import UIKit
import Combine
import MiVIPSdk
import MiVIPApi

// MARK: - Models & Errors

enum MiVIPRequestState {
    case idle, loading, success(MiVIPApi.RequestResult), failure(MiVIPError)
}

enum MiVIPError: Error {
    case sdk(String), validation(String)
    var userMessage: String {
        switch self {
        case .sdk(let msg): return "SDK Error: \(msg)"
        case .validation(let msg): return "Validation: \(msg)"
        }
    }
}

typealias RequestStatusDelegate = MiVIPSdk.RequestStatusDelegate

// MARK: - Protocols

protocol MiVIPServiceProtocol {
    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?)
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?)
    func getRequestId(from code: String) async throws -> String?
    func showHistory(vc: UIViewController)
    func showAccount(vc: UIViewController)
}

// MARK: - Dependency Injection

class DependencyContainer {
    static let shared = DependencyContainer()
    let mivipService: MiVIPServiceProtocol
    
    init() {
        // Detailed License Debugging
        print("--------------------------------------------------")
        print("DEBUG: MiVIP License Diagnostic")
        print("DEBUG: Active Bundle ID: \(Bundle.main.bundleIdentifier ?? "nil")")
        
        let license = Bundle.main.infoDictionary?["MISNAP_LICENSE_KEY"] as? String
        print("DEBUG: License present in Info.plist: \(license != nil)")
        
        if let license = license {
            print("DEBUG: License Length: \(license.count)")
            if let data = Data(base64Encoded: license), let str = String(data: data, encoding: .utf8) {
                if let range = str.range(of: "\"expiry\":\"[^\"]*\"", options: .regularExpression) {
                    print("DEBUG: Internal \(str[range])")
                }
            }
        }
        print("--------------------------------------------------")

        do {
            self.mivipService = try MiVIPService()
            print("DEBUG: MiVIPService successfully initialized real SDK")
        } catch {
            print("⚠️ MiVIPService init failed: \(error)")
            self.mivipService = MiVIPServiceFallback(error: error)
        }
    }
    
    func makeMiVIPHubViewModel() -> MiVIPHubViewModel { return MiVIPHubViewModel() }
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
        let vc = ViewController(viewModel: vm, coordinator: self)
        router.setRootViewController(vc, animated: true)
    }

    func coordinate(to route: MiVIPRoute) {
        guard let vm = viewModel else { return }
        switch route {
        case .qr(let url):
            vm.requestState = .loading
            container.mivipService.startQRCodeScan(vc: router.navigationController, delegate: vm, callbackURL: url)
        case .request(let id, let url):
            vm.requestState = .loading
            container.mivipService.openRequest(vc: router.navigationController, id: id, delegate: vm, callbackURL: url)
        case .code(let code, let url):
            vm.requestState = .loading
            Task { @MainActor in
                do {
                    if let id = try await container.mivipService.getRequestId(from: code) {
                        container.mivipService.openRequest(vc: router.navigationController, id: id, delegate: vm, callbackURL: url)
                    }
                } catch { vm.requestState = .failure(.sdk(error.localizedDescription)) }
            }
        case .history: container.mivipService.showHistory(vc: router.navigationController)
        case .account: container.mivipService.showAccount(vc: router.navigationController)
        }
    }
}

enum MiVIPRoute {
    case qr(String?), request(id: String, url: String?), code(code: String, url: String?), history, account
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
        mivipHub.setSoundsDisabled(true)
        mivipHub.setFontNameRegular(fontName: "WorkSans-Regular")
    }
    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?) {
        mivipHub.qrCode(vc: vc, requestStatusDelegate: delegate, documentCallbackUrl: callbackURL)
    }
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) {
        mivipHub.request(vc: vc, miVipRequestId: id, requestStatusDelegate: delegate, documentCallbackUrl: callbackURL)
    }
    func getRequestId(from code: String) async throws -> String? {
        try await withCheckedThrowingContinuation { c in
            mivipHub.getRequestIdFromCode(code: code) { id, err in
                if let err = err { c.resume(throwing: MiVIPError.sdk(err)) }
                else { c.resume(returning: id) }
            }
        }
    }
    func showHistory(vc: UIViewController) { mivipHub.history(vc: vc) }
    func showAccount(vc: UIViewController) { mivipHub.account(vc: vc) }
}

class MiVIPServiceFallback: MiVIPServiceProtocol {
    let error: Error
    init(error: Error) { self.error = error }
    func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?) { show(vc) }
    func openRequest(vc: UIViewController, id: String, delegate: RequestStatusDelegate, callbackURL: String?) { show(vc) }
    func getRequestId(from code: String) async throws -> String? { throw error }
    func showHistory(vc: UIViewController) { show(vc) }
    func showAccount(vc: UIViewController) { show(vc) }
    private func show(_ vc: UIViewController) {
        let alert = UIAlertController(title: "SDK Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}

// MARK: - Views

class PrimaryButton: UIButton {
    override init(frame: CGRect) { super.init(frame: frame); setup() }
    required init?(coder: NSCoder) { super.init(coder: coder); setup() }
    private func setup() {
        if #available(iOS 15.0, *) {
            var c = UIButton.Configuration.filled()
            c.baseBackgroundColor = UIColor(red: 226/255, green: 0, blue: 26/255, alpha: 1)
            c.cornerStyle = .large
            configuration = c
        } else {
            backgroundColor = .red
            layer.cornerRadius = 12
        }
    }
}

// MARK: - View Controller

class ViewController: UIViewController {
    private let viewModel: MiVIPHubViewModel
    private let coordinator: MiVIPCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    private let stackView = UIStackView()
    private let callbackTF = UITextField()
    private let idTF = UITextField()
    private let codeTF = UITextField()
    private let loading = UIActivityIndicatorView(style: .large)

    init(viewModel: MiVIPHubViewModel, coordinator: MiVIPCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "MiVIP Demo"
        
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        configureTF(callbackTF, placeholder: "Callback URL")
        configureTF(idTF, placeholder: "Request ID")
        configureTF(codeTF, placeholder: "4 Digit Code")
        
        stackView.addArrangedSubview(callbackTF)
        stackView.addArrangedSubview(createBtn("SCAN QR", #selector(qrAction)))
        stackView.addArrangedSubview(idTF)
        stackView.addArrangedSubview(createBtn("OPEN BY ID", #selector(idAction)))
        stackView.addArrangedSubview(codeTF)
        stackView.addArrangedSubview(createBtn("OPEN BY CODE", #selector(codeAction)))
        stackView.addArrangedSubview(createBtn("HISTORY", #selector(historyAction)))
        stackView.addArrangedSubview(createBtn("ACCOUNT", #selector(accountAction)))
        
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        loading.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loading.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    private func configureTF(_ tf: UITextField, placeholder: String) {
        tf.borderStyle = .roundedRect
        tf.placeholder = placeholder
        tf.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }

    private func createBtn(_ title: String, _ action: Selector) -> UIButton {
        let btn = PrimaryButton()
        btn.setTitle(title, for: .normal)
        btn.addTarget(self, action: action, for: .touchUpInside)
        btn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return btn
    }

    private func setupBindings() {
        viewModel.$requestState
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                switch state {
                case .loading: self?.loading.startAnimating()
                case .success(let res): self?.loading.stopAnimating(); self?.alert("Success", "Result: \(res)")
                case .failure(let err): self?.loading.stopAnimating(); self?.alert("Error", err.userMessage)
                default: self?.loading.stopAnimating()
                }
            }.store(in: &cancellables)
    }

    private func alert(_ t: String, _ m: String) {
        let a = UIAlertController(title: t, message: m, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    @objc private func qrAction() { coordinator.coordinate(to: .qr(callbackTF.text)) }
    @objc private func idAction() { coordinator.coordinate(to: .request(id: idTF.text ?? "", url: callbackTF.text)) }
    @objc private func codeAction() { coordinator.coordinate(to: .code(code: codeTF.text ?? "", url: callbackTF.text)) }
    @objc private func historyAction() { coordinator.coordinate(to: .history) }
    @objc private func accountAction() { coordinator.coordinate(to: .account) }
}
