# Accessibility Audit Report - MiVIP iOS Example Apps

**Audit Date**: 2025-12-19
**Target**: MiVIP SDK v3.6.15 Example Applications
**Auditor**: Axiom Accessibility Auditor

## Executive Summary

This accessibility audit identifies critical issues in the MiVIP example applications that pose **HIGH risk for App Store rejection** and violate accessibility requirements. The primary concerns are:

- Non-accessible custom UI controls (UIView as buttons)
- Missing VoiceOver labels and traits
- No Dynamic Type support (hard-coded font sizes)
- Potential color contrast issues

**App Store Approval Risk**: **HIGH**

---

## Repository Status

**Note**: This repository is a binary framework distribution containing pre-compiled XCFrameworks. The audit is based on example application code patterns documented in CLAUDE.md and previously reviewed source files.

**Audited Files**:
- `Examples/whitelabel_demo/whitelabel_demo/ViewController.swift`
- `Examples/ios-webviewdemo/HooyuWView/` (patterns)

---

## Critical Issues

### 🚨 CRITICAL-001: Missing VoiceOver Labels on Interactive Elements

**Location**: `ViewController.swift:118-136`

**Code**:
```swift
private func addButton(scope: String, y: CGFloat) {
    let button = UIView(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
    button.backgroundColor = UIColor.lightGray

    let action = MenuGesture()
    action.addTarget(self, action: #selector(buttonAction))
    action.scope = scope
    button.addGestureRecognizer(action)  // ⚠️ Not accessible to VoiceOver

    let textLabel = UILabel()
    textLabel.text = scope
    // ❌ NO accessibility configuration
}
```

**Issues**:
1. ❌ **UIView used as button** - Not inherently accessible
2. ❌ **No `accessibilityLabel`** - VoiceOver reads nothing or generic info
3. ❌ **No `accessibilityTraits`** - VoiceOver doesn't know it's a button
4. ❌ **No `isAccessibilityElement = true`** - May be skipped entirely
5. ❌ **Nested label not grouped** - VoiceOver might read separately

**Severity**: **CRITICAL**

**Impact**:
- **App Store Risk**: HIGH - Apple rejects apps with non-accessible primary UI
- **Legal Risk**: Violates accessibility requirements (ADA/Section 508 in US)
- **User Impact**: VoiceOver users cannot navigate the app

**WCAG 2.1 Violations**:
- **4.1.2 Name, Role, Value** (Level A) - Controls must have accessible names and roles
- **2.1.1 Keyboard** (Level A) - Interactive elements must be keyboard accessible

**Recommended Fix**:
```swift
private func addButton(scope: String, y: CGFloat) {
    let button = UIView(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
    button.backgroundColor = UIColor.lightGray

    // ✅ Make accessible
    button.isAccessibilityElement = true
    button.accessibilityLabel = getAccessibilityLabel(for: scope)
    button.accessibilityTraits = .button
    button.accessibilityHint = getAccessibilityHint(for: scope)

    let action = MenuGesture()
    action.addTarget(self, action: #selector(buttonAction))
    action.scope = scope
    button.addGestureRecognizer(action)

    let textLabel = UILabel()
    textLabel.text = scope
    textLabel.isAccessibilityElement = false  // ✅ Hide to avoid duplication
    textLabel.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width-40, height: 60)
    button.addSubview(textLabel)

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
```

**Better Alternative** - Use UIButton (inherently accessible):
```swift
private func addButton(scope: String, y: CGFloat) {
    let button = UIButton(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
    button.backgroundColor = UIColor.lightGray
    button.setTitle(scope, for: .normal)
    button.setTitleColor(.darkText, for: .normal)
    button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title2)
    button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
    button.tag = getTag(for: scope)  // Store scope in tag

    // Accessibility comes free with UIButton!
    button.accessibilityLabel = getAccessibilityLabel(for: scope)
    button.accessibilityHint = getAccessibilityHint(for: scope)

    self.view.addSubview(button)
}
```

---

## High Priority Issues

### ⚠️ HIGH-001: Missing VoiceOver Labels on Text Fields

**Location**: `ViewController.swift:138-167`

**Code**:
```swift
private func addRequestTextField(y: CGFloat) {
    requestIdTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
    requestIdTextField.backgroundColor = UIColor.white
    requestIdTextField.textColor = UIColor.black
    requestIdTextField.textAlignment = .center
    requestIdTextField.attributedPlaceholder = NSAttributedString(
        string: "request ID to open",
        attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray]
    )
    requestIdTextField.tintColor = UIColor.gray
    self.view.addSubview(requestIdTextField)
    // ❌ NO accessibility configuration
}
```

**Issues**:
1. ❌ **No `accessibilityLabel`** - VoiceOver only reads placeholder (confusing)
2. ❌ **No `accessibilityHint`** - Users don't know what format to enter
3. ⚠️ **Placeholder used as label** - Not best practice, placeholder disappears on input

**Severity**: **HIGH**

**Impact**:
- Form inputs without proper labels are very difficult for VoiceOver users
- Users may not understand what to enter in each field

**WCAG 2.1 Violations**:
- **3.3.2 Labels or Instructions** (Level A) - Form inputs must have clear labels

**Recommended Fix**:
```swift
private func addRequestTextField(y: CGFloat) {
    requestIdTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
    requestIdTextField.backgroundColor = UIColor.white
    requestIdTextField.textColor = UIColor.black
    requestIdTextField.textAlignment = .center
    requestIdTextField.attributedPlaceholder = NSAttributedString(
        string: "request ID to open",
        attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray]
    )
    requestIdTextField.tintColor = UIColor.gray

    // ✅ Add accessibility
    requestIdTextField.accessibilityLabel = "Request ID"
    requestIdTextField.accessibilityHint = "Enter the verification request ID to open directly"

    self.view.addSubview(requestIdTextField)
}

private func addCallbackTextField(y: CGFloat) {
    documentCallbackTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
    documentCallbackTextField.backgroundColor = UIColor.white
    documentCallbackTextField.textColor = UIColor.black
    documentCallbackTextField.textAlignment = .center
    documentCallbackTextField.attributedPlaceholder = NSAttributedString(
        string: "document callback URL",
        attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray]
    )
    documentCallbackTextField.tintColor = UIColor.gray

    // ✅ Add accessibility
    documentCallbackTextField.accessibilityLabel = "Document Callback URL"
    documentCallbackTextField.accessibilityHint = "Optional URL to receive document processing notifications"

    self.view.addSubview(documentCallbackTextField)
}

private func addRequestCodeTextField(y: CGFloat) {
    requestCodeTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
    requestCodeTextField.backgroundColor = UIColor.white
    requestCodeTextField.textColor = UIColor.black
    requestCodeTextField.textAlignment = .center
    requestCodeTextField.keyboardType = .numberPad
    requestCodeTextField.attributedPlaceholder = NSAttributedString(
        string: "4 digit request code",
        attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray]
    )
    requestCodeTextField.tintColor = UIColor.gray

    // ✅ Add accessibility
    requestCodeTextField.accessibilityLabel = "Request Code"
    requestCodeTextField.accessibilityHint = "Enter the 4-digit verification request code"

    self.view.addSubview(requestCodeTextField)
}
```

---

### ⚠️ HIGH-002: No Dynamic Type Support (Hard-Coded Font Sizes)

**Location**: `ViewController.swift:130`

**Code**:
```swift
textLabel.font = UIFont.systemFont(ofSize: 25, weight: .semibold)  // ❌ Fixed size
```

**Issues**:
1. ❌ **Fixed font size** - Won't scale with user's accessibility text size settings
2. ❌ **No `adjustsFontForContentSizeCategory`** - Dynamic Type disabled

**Severity**: **HIGH**

**Impact**:
- **App Store Risk**: HIGH - Required for approval since iOS 11
- **User Impact**: Users with vision impairments cannot read text
- Violates Apple Human Interface Guidelines

**WCAG 2.1 Violations**:
- **1.4.4 Resize Text** (Level AA) - Text must be resizable up to 200%

**Recommended Fix**:
```swift
// ✅ Use text styles that scale automatically
textLabel.font = UIFont.preferredFont(forTextStyle: .title2)
textLabel.adjustsFontForContentSizeCategory = true

// For custom fonts (WorkSans in this example app):
let font = UIFont(name: "WorkSans-SemiBold", size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
let fontMetrics = UIFontMetrics(forTextStyle: .title2)
textLabel.font = fontMetrics.scaledFont(for: font ?? UIFont.preferredFont(forTextStyle: .title2))
textLabel.adjustsFontForContentSizeCategory = true
```

**Layout Considerations**:
```swift
// Ensure layout adjusts to larger text
textLabel.numberOfLines = 0  // Allow wrapping
textLabel.lineBreakMode = .byWordWrapping

// Update button height to accommodate larger text
let button = UIView(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
// ✅ Use Auto Layout instead for dynamic sizing
button.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    button.heightAnchor.constraint(greaterThanOrEqualToConstant: 60)
])
```

---

## Medium Priority Issues

### ⚠️ MEDIUM-001: Potential Color Contrast Issue

**Location**: `ViewController.swift:120, 131`

**Code**:
```swift
button.backgroundColor = UIColor.lightGray
textLabel.textColor = UIColor.darkText
```

**Issue**: Light gray background with dark text may not meet WCAG AA contrast ratio (4.5:1 for normal text, 3:1 for large text).

**Severity**: **MEDIUM**

**Impact**:
- May be difficult for users with low vision to read
- Could fail App Store review if contrast is too low

**WCAG 2.1 Violations**:
- **1.4.3 Contrast (Minimum)** (Level AA) - 4.5:1 for normal text, 3:1 for large text

**Needs Testing**:
- Exact contrast ratio depends on specific UIColor values
- Test with accessibility inspector or online contrast checker

**Recommended Fix**:
```swift
// ✅ Use semantic colors that adapt to light/dark mode
button.backgroundColor = .systemGray4  // Better contrast, adapts to dark mode
textLabel.textColor = .label  // Adapts automatically to light/dark mode

// Or use system colors with guaranteed contrast
button.backgroundColor = .secondarySystemGroupedBackground
textLabel.textColor = .label
```

**Testing Instructions**:
1. Open Xcode Accessibility Inspector
2. Enable "Color Contrast Calculator"
3. Verify ratio ≥ 4.5:1 for normal text or ≥ 3:1 for large text (18pt+)

---

## Low Priority Issues

### ℹ️ LOW-001: Keyboard Dismissal Not VoiceOver-Friendly

**Location**: `ViewController.swift:172-176`

**Code**:
```swift
func hideKeyboardWhenTappedAround() {
    let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
    tap.cancelsTouchesInView = false
    view.addGestureRecognizer(tap)  // ❌ Not discoverable to VoiceOver users
}
```

**Issue**: VoiceOver users may not discover the tap-to-dismiss gesture.

**Severity**: **LOW**

**Impact**:
- Minor inconvenience - VoiceOver has built-in keyboard dismissal
- Not a blocker but reduces UX quality

**Recommended Enhancement**:
```swift
// ✅ Add toolbar with Done button for better accessibility
extension UITextField {
    func addDoneButtonToolbar(onDone: (target: Any, action: Selector)? = nil) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: onDone?.target,
            action: onDone?.action
        )

        toolbar.items = [flexSpace, doneButton]
        self.inputAccessoryView = toolbar
    }
}

// Usage in viewDidLoad:
requestIdTextField.addDoneButtonToolbar(onDone: (target: self, action: #selector(dismissKeyboard)))
documentCallbackTextField.addDoneButtonToolbar(onDone: (target: self, action: #selector(dismissKeyboard)))
requestCodeTextField.addDoneButtonToolbar(onDone: (target: self, action: #selector(dismissKeyboard)))
```

---

## Touch Target Compliance

### ✅ PASSED: Touch Target Size

**Location**: `ViewController.swift:119`

**Code**:
```swift
let button = UIView(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
```

**Status**: ✅ **COMPLIANT**

**Details**:
- Height: 60pt (exceeds 44pt minimum)
- Width: Full width minus margins (exceeds 44pt minimum)
- Meets Apple HIG and WCAG 2.5.5 (Target Size) Level AAA

---

## Summary

### Issues by Severity

| Severity | Count | Status |
|----------|-------|--------|
| **CRITICAL** | 1 | 🚨 App Store blocker |
| **HIGH** | 2 | ⚠️ Must fix before submission |
| **MEDIUM** | 1 | ⚠️ Recommended to fix |
| **LOW** | 1 | ℹ️ Nice to have |
| **PASSED** | 1 | ✅ Compliant |

### App Store Approval Risk: **HIGH**

Apple frequently rejects apps for:
- ✅ **Non-accessible custom controls** ← Found in this app (CRITICAL-001)
- ✅ **Missing Dynamic Type support** ← Found in this app (HIGH-002)
- ⚠️ **Poor color contrast** ← Needs verification (MEDIUM-001)

---

## Priority Action Items

### 🔴 Immediate (Before Submission)

1. **Fix CRITICAL-001**: Add accessibility labels, traits, and hints to all custom UIView buttons
   - Estimated effort: 2 hours
   - Files: `ViewController.swift:118-136`

2. **Fix HIGH-002**: Implement Dynamic Type support
   - Estimated effort: 3 hours
   - Files: All UI creation methods
   - Test with Settings → Accessibility → Display & Text Size → Larger Text

3. **Fix HIGH-001**: Add accessibility labels to all text fields
   - Estimated effort: 30 minutes
   - Files: `ViewController.swift:138-167`

### 🟡 Recommended

4. **Verify MEDIUM-001**: Test color contrast ratios
   - Estimated effort: 1 hour
   - Use Xcode Accessibility Inspector

5. **Implement LOW-001**: Add Done button toolbar for keyboard dismissal
   - Estimated effort: 1 hour

---

## Testing Checklist

Before submitting to App Store, verify:

### VoiceOver Testing
- [ ] Enable VoiceOver (Settings → Accessibility → VoiceOver)
- [ ] Navigate through all buttons - verify each announces correctly
- [ ] Test all text fields - verify labels are clear
- [ ] Verify no unlabeled interactive elements
- [ ] Test gesture actions work with VoiceOver gestures

### Dynamic Type Testing
- [ ] Settings → Accessibility → Display & Text Size → Larger Text
- [ ] Set to maximum size
- [ ] Verify all text scales appropriately
- [ ] Verify layout doesn't break (no truncation)
- [ ] Test with smaller text sizes too

### Color & Contrast Testing
- [ ] Test in light mode
- [ ] Test in dark mode
- [ ] Use Xcode Accessibility Inspector to verify contrast ratios
- [ ] Enable Settings → Accessibility → Display & Text Size → Increase Contrast

### Keyboard Navigation
- [ ] Connect external keyboard
- [ ] Navigate using Tab key
- [ ] Verify focus indicators are visible
- [ ] Test Return/Enter key activates buttons

### Other Accessibility Features
- [ ] Test with Reduce Motion enabled
- [ ] Test with Bold Text enabled
- [ ] Test with Button Shapes enabled

---

## Automated Testing Recommendations

### Unit Tests
```swift
func testButtonsHaveAccessibilityLabels() {
    let vc = ViewController()
    vc.loadViewIfNeeded()

    let buttons = vc.view.subviews.filter { $0.accessibilityTraits.contains(.button) }

    for button in buttons {
        XCTAssertNotNil(button.accessibilityLabel, "Button missing accessibility label")
        XCTAssertTrue(button.isAccessibilityElement, "Button not marked as accessibility element")
    }
}

func testTextFieldsHaveAccessibilityLabels() {
    let vc = ViewController()
    vc.loadViewIfNeeded()

    let textFields = vc.view.subviews.compactMap { $0 as? UITextField }

    for textField in textFields {
        XCTAssertNotNil(textField.accessibilityLabel, "TextField missing accessibility label")
        XCTAssertFalse(textField.accessibilityLabel?.isEmpty ?? true, "TextField has empty accessibility label")
    }
}
```

### UI Tests
```swift
func testVoiceOverNavigation() {
    let app = XCUIApplication()
    app.launch()

    // Enable accessibility mode for testing
    XCUIDevice.shared.press(.home)

    let qrButton = app.buttons["Scan QR Code"]
    XCTAssertTrue(qrButton.exists, "QR button not accessible")

    let requestIDField = app.textFields["Request ID"]
    XCTAssertTrue(requestIDField.exists, "Request ID field not accessible")
}
```

---

## Resources

### Apple Documentation
- [Accessibility Programming Guide for iOS](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/iPhoneAccessibility/Introduction/Introduction.html)
- [UIAccessibility Protocol](https://developer.apple.com/documentation/uikit/uiaccessibility)
- [Supporting Dynamic Type](https://developer.apple.com/documentation/uikit/uifont/scaling_fonts_automatically)
- [Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)

### Standards
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Section 508 Standards](https://www.section508.gov/)
- [ADA Requirements](https://www.ada.gov/)

### Testing Tools
- Xcode Accessibility Inspector
- [Contrast Ratio Calculator](https://contrast-ratio.com/)
- [Color Oracle](https://colororacle.org/) - Color blindness simulator
- VoiceOver (built into iOS)

---

## Appendix: Complete Fixed Implementation

See the following complete implementation with all accessibility fixes applied:

```swift
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

        // Set view accessibility
        view.accessibilityLabel = "MiVIP Demo Home"

        var y = 100.0
        addCallbackTextField(y: y)
        y+=70
        addButton(scope: "QR", y: y)
        y+=65
        addRequestTextField(y: y)
        y+=50
        addButton(scope: "request", y: y)
        y+=65
        addRequestCodeTextField(y: y)
        y+=50
        addButton(scope: "code", y: y)
        y+=65
        addButton(scope: "history", y: y)
        y+=65
        addButton(scope: "account", y: y)
    }

    @objc fileprivate func buttonAction(gesture: MenuGesture) {
        guard let scope = gesture.scope else { return }

        print(MiVIPHub.version)

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
                guard let idRequest = requestIdTextField.text else { return }
                mivip.request(vc: self, miVipRequestId: idRequest, requestStatusDelegate: self, documentCallbackUrl: documentCallbackTextField.text)
            case "code":
                guard let code = requestCodeTextField.text else { return }
                mivip.getRequestIdFromCode(code: code) { (idRequest, error) in
                    DispatchQueue.main.async { [weak self] in
                        guard let strongSelf = self else { return }
                        if let idRequest = idRequest {
                            mivip.request(vc: strongSelf, miVipRequestId: idRequest, requestStatusDelegate: strongSelf, documentCallbackUrl: strongSelf.documentCallbackTextField.text)
                        }
                        if let error = error {
                            debugPrint("Error = \(error)")
                        }
                    }
                }
            default:
                print("Unknown scope")
            }

        } catch let error as MiVIPHub.LicenseError {
            print(error.rawValue)
        } catch {
            print(error)
        }
    }

    deinit {
        // Clean up gesture recognizers to prevent retain cycles
        view.subviews.forEach { subview in
            subview.gestureRecognizers?.forEach { $0.removeTarget(nil, action: nil) }
        }
    }
}

extension ViewController: MiVIPSdk.RequestStatusDelegate {

    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        debugPrint("MiVIP: RequestStatus = \(status), RequestResult \(result), ScoreResponse \(scoreResponse), MiVIPRequest \(request)")
    }

    func error(err: String) {
        debugPrint("MiVIP: \(err)")
    }
}

// MARK: - UI with Full Accessibility Support

extension ViewController {

    private func addButton(scope: String, y: CGFloat) {
        let button = UIView(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
        button.backgroundColor = .systemGray4  // ✅ Better contrast

        // ✅ Full accessibility support
        button.isAccessibilityElement = true
        button.accessibilityLabel = getAccessibilityLabel(for: scope)
        button.accessibilityTraits = .button
        button.accessibilityHint = getAccessibilityHint(for: scope)

        let action = MenuGesture()
        action.addTarget(self, action: #selector(buttonAction))
        action.scope = scope
        button.addGestureRecognizer(action)

        let textLabel = UILabel()
        textLabel.text = scope
        textLabel.textAlignment = .center

        // ✅ Dynamic Type support
        textLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        textLabel.adjustsFontForContentSizeCategory = true

        textLabel.textColor = .label  // ✅ Adapts to dark mode
        textLabel.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width-40, height: 60)
        textLabel.isAccessibilityElement = false  // ✅ Hide from VoiceOver (button already has label)
        button.addSubview(textLabel)

        self.view.addSubview(button)
    }

    private func addRequestTextField(y: CGFloat) {
        requestIdTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
        requestIdTextField.backgroundColor = .systemBackground
        requestIdTextField.textColor = .label
        requestIdTextField.textAlignment = .center
        requestIdTextField.attributedPlaceholder = NSAttributedString(
            string: "request ID to open",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText]
        )
        requestIdTextField.tintColor = .tintColor

        // ✅ Accessibility
        requestIdTextField.accessibilityLabel = "Request ID"
        requestIdTextField.accessibilityHint = "Enter the verification request ID to open directly"

        // ✅ Done button for keyboard
        requestIdTextField.addDoneButtonToolbar(onDone: (target: self, action: #selector(dismissKeyboard)))

        self.view.addSubview(requestIdTextField)
    }

    private func addCallbackTextField(y: CGFloat) {
        documentCallbackTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
        documentCallbackTextField.backgroundColor = .systemBackground
        documentCallbackTextField.textColor = .label
        documentCallbackTextField.textAlignment = .center
        documentCallbackTextField.attributedPlaceholder = NSAttributedString(
            string: "document callback URL",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText]
        )
        documentCallbackTextField.tintColor = .tintColor

        // ✅ Accessibility
        documentCallbackTextField.accessibilityLabel = "Document Callback URL"
        documentCallbackTextField.accessibilityHint = "Optional URL to receive document processing notifications"

        // ✅ Done button for keyboard
        documentCallbackTextField.addDoneButtonToolbar(onDone: (target: self, action: #selector(dismissKeyboard)))

        self.view.addSubview(documentCallbackTextField)
    }

    private func addRequestCodeTextField(y: CGFloat) {
        requestCodeTextField = UITextField(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 50))
        requestCodeTextField.backgroundColor = .systemBackground
        requestCodeTextField.textColor = .label
        requestCodeTextField.textAlignment = .center
        requestCodeTextField.keyboardType = .numberPad
        requestCodeTextField.attributedPlaceholder = NSAttributedString(
            string: "4 digit request code",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.placeholderText]
        )
        requestCodeTextField.tintColor = .tintColor

        // ✅ Accessibility
        requestCodeTextField.accessibilityLabel = "Request Code"
        requestCodeTextField.accessibilityHint = "Enter the 4-digit verification request code"

        // ✅ Done button for keyboard
        requestCodeTextField.addDoneButtonToolbar(onDone: (target: self, action: #selector(dismissKeyboard)))

        self.view.addSubview(requestCodeTextField)
    }

    // MARK: - Accessibility Helpers

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
}

// MARK: - Keyboard Helpers

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

extension UITextField {

    func addDoneButtonToolbar(onDone: (target: Any, action: Selector)? = nil) {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: onDone?.target,
            action: onDone?.action
        )

        toolbar.items = [flexSpace, doneButton]
        self.inputAccessoryView = toolbar
    }
}

private class MenuGesture: UITapGestureRecognizer {
    var scope: String?
}
```

---

**Report Generated**: 2025-12-19
**Next Review**: Before App Store submission
**Contact**: Development team for implementation questions
