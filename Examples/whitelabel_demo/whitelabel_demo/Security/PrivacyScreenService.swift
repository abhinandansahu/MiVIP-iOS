import UIKit

class PrivacyScreenService {
    static let shared = PrivacyScreenService()
    private var blurEffectView: UIVisualEffectView?

    private init() {}

    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(showPrivacyScreen), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hidePrivacyScreen), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc func showPrivacyScreen() {
        guard blurEffectView == nil else { return }
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 9999
        
        // Add logo or text to the privacy screen
        let label = UILabel()
        label.text = NSLocalizedString("privacy.screen.message", comment: "Message shown on privacy screen")
        label.textColor = .white
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        blurEffectView.contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: blurEffectView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: blurEffectView.centerYAnchor)
        ])
        
        window.addSubview(blurEffectView)
        self.blurEffectView = blurEffectView
    }

    @objc func hidePrivacyScreen() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
        
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?
            .viewWithTag(9999)?.removeFromSuperview()
    }
}
