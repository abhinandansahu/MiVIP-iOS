import UIKit

struct ColorPalette {
    static let primaryButton = UIColor { traitCollection in
        return traitCollection.userInterfaceStyle == .dark ?
            UIColor(red: 0.51, green: 0.21, blue: 0.55, alpha: 1.0) :
            UIColor(red: 0.89, green: 0.09, blue: 0.21, alpha: 1.0)
    }
    
    static let disabledButton = UIColor.systemGray4
    
    static let background = UIColor.systemBackground
    static let secondaryBackground = UIColor.secondarySystemBackground
    static let text = UIColor.label
    static let secondaryText = UIColor.secondaryLabel
    
    static let accent = UIColor.systemBlue
}
