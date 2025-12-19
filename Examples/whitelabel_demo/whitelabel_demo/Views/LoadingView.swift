import UIKit

class LoadingView: UIView {
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let messageLabel = UILabel()
    private let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        blurEffectView.frame = bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blurEffectView)

        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 16
        containerStack.alignment = .center
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStack)

        messageLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .label
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        containerStack.addArrangedSubview(activityIndicator)
        containerStack.addArrangedSubview(messageLabel)

        NSLayoutConstraint.activate([
            containerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            containerStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40)
        ])
    }

    func show(in view: UIView, message: String = "Loading...") {
        self.frame = view.bounds
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        messageLabel.text = message
        activityIndicator.startAnimating()
        
        self.alpha = 0
        view.addSubview(self)
        
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
        
        UIAccessibility.post(notification: .screenChanged, argument: self)
    }

    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.activityIndicator.stopAnimating()
            self.removeFromSuperview()
        }
    }
}
