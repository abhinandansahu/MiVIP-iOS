import UIKit

class PrivacyScreenService {
    static let shared = PrivacyScreenService()
    private var blurEffectView: UIVisualEffectView?

    private init() {}

    func showPrivacyScreen() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = window.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = 9999
        
        window.addSubview(blurEffectView)
        self.blurEffectView = blurEffectView
    }

    func hidePrivacyScreen() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
        
        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?
            .viewWithTag(9999)?.removeFromSuperview()
    }
}
