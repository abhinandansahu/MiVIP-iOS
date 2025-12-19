import UIKit

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
        setTitleColor(isEnabled ? .white : .systemGray, for: .normal)
    }

    @objc private func touchDown() {
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func touchUp() {
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateColors()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }
    
    override func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        let targetedPreview = UITargetedPreview(view: self)
        return UIPointerStyle(effect: .automatic(targetedPreview))
    }
}
