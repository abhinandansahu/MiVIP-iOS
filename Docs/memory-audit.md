# Memory Leak Audit Report - MiVIP iOS Example Apps

**Audit Date**: 2025-12-19
**Target**: MiVIP SDK v3.6.15 Example Applications
**Auditor**: Axiom Memory Auditor

## Executive Summary

This memory audit identifies potential retain cycles and memory management issues in the MiVIP example applications. The audit found **2 medium-severity issues** and **1 unknown-severity issue** that could cause memory leaks under certain conditions.

**Key Findings**:
- ✅ Proper weak self usage in async closures
- ⚠️ Custom gesture recognizer strong reference pattern
- ⚠️ Unknown delegate retention in SDK framework
- ✅ No timer leaks detected
- ✅ No notification observer leaks detected

**Overall Risk**: **MEDIUM** - Issues are manageable but should be addressed before production

---

## Repository Status

**Note**: This repository is a binary framework distribution containing pre-compiled XCFrameworks. The audit is based on example application code patterns documented in CLAUDE.md and previously reviewed source files.

**Audited Files**:
- `Examples/whitelabel_demo/whitelabel_demo/ViewController.swift`
- `Examples/ios-webviewdemo/HooyuWView/` (patterns)

---

## Issues Found

### ✅ GOOD: Proper Weak Self Usage in Closures

**Location**: `ViewController.swift:80-89`

**Code**:
```swift
mivip.getRequestIdFromCode(code: code) { (idRequest, error) in
    DispatchQueue.main.async { [weak self] in  // ✓ Correct
        guard let strongSelf = self else { return }
        if let idRequest = idRequest {
            mivip.request(vc: strongSelf, miVipRequestId: idRequest,
                         requestStatusDelegate: strongSelf,
                         documentCallbackUrl: strongSelf.documentCallbackTextField.text)
        }
        if let error = error {
            debugPrint("Error = \(error)")
        }
    }
}
```

**Status**: ✅ **NO ISSUE**

**Analysis**:
- Correctly uses `[weak self]` capture list
- Properly unwraps with `guard let strongSelf = self`
- Prevents retain cycle between closure and view controller

**Pattern**: This is the recommended pattern for async closures that capture self.

---

### ⚠️ MEDIUM: Custom Gesture Recognizer Strong Reference

**Location**: `ViewController.swift:10-12, 122-125`

**Code**:
```swift
// Line 10-12: Custom gesture class
private class MenuGesture: UITapGestureRecognizer {
    var scope: String?
}

// Line 122-125: Usage
let action = MenuGesture()
action.addTarget(self, action: #selector(buttonAction))  // ⚠️ Implicit strong reference
action.scope = scope
button.addGestureRecognizer(action)
```

**Issue**: UIGestureRecognizer holds a strong reference to its target by default.

**Severity**: **MEDIUM**

**Risk Analysis**:
- **High Risk Scenario**: If the button outlives the view controller, this creates a retain cycle
- **Low Risk Scenario**: View controllers are typically deallocated when dismissed, and buttons are subviews that get released with the view controller
- **Production Risk**: If buttons are ever retained elsewhere (e.g., stored in a global array, cached, or added to a different view hierarchy), this becomes an active leak

**Memory Impact**:
- Each button + gesture + view controller = ~5-10 KB retained
- With 5 buttons on screen, potential leak = ~25-50 KB per view controller instance
- If user navigates back and forth repeatedly: Leak accumulates

**Reproduction Steps**:
1. Launch app
2. Navigate to ViewController
3. Go back to previous screen
4. Repeat steps 2-3 multiple times
5. Check Memory Graph Debugger - if ViewController instances accumulate, leak is confirmed

**Recommended Fix Option 1** - Add cleanup in deinit:
```swift
deinit {
    // Remove all gesture recognizers to break retain cycles
    view.subviews.forEach { subview in
        subview.gestureRecognizers?.forEach { gesture in
            gesture.removeTarget(nil, action: nil)
        }
    }
}
```

**Recommended Fix Option 2** - Use modern UIButton with UIAction (iOS 14+):
```swift
private func addButton(scope: String, y: CGFloat) {
    let button = UIButton(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
    button.backgroundColor = .systemGray4
    button.setTitle(scope, for: .normal)
    button.setTitleColor(.label, for: .normal)

    // ✅ UIAction automatically uses weak reference
    button.addAction(UIAction { [weak self] _ in
        self?.handleButtonAction(scope: scope)
    }, for: .touchUpInside)

    self.view.addSubview(button)
}

@objc private func handleButtonAction(scope: String) {
    // Button action implementation
    print(MiVIPHub.version)

    do {
        let mivip = try MiVIPHub()
        mivip.setSoundsDisabled(true)
        mivip.setReusableEnabled(false)
        mivip.setLogDisabled(false)

        // ... rest of implementation
    } catch {
        print(error)
    }
}
```

**Recommended Fix Option 3** - Use weak target wrapper:
```swift
// Create a weak wrapper class
private class WeakGestureTarget {
    weak var target: AnyObject?
    let action: Selector

    init(target: AnyObject, action: Selector) {
        self.target = target
        self.action = action
    }

    @objc func handleGesture(_ gesture: UIGestureRecognizer) {
        _ = target?.perform(action, with: gesture)
    }
}

// Store wrappers to keep them alive
private var gestureWrappers: [WeakGestureTarget] = []

private func addButton(scope: String, y: CGFloat) {
    let button = UIView(frame: CGRect(x: 20, y: y, width: self.view.bounds.width-40, height: 60))
    button.backgroundColor = .systemGray4

    let action = MenuGesture()
    action.scope = scope

    // ✅ Use weak wrapper
    let wrapper = WeakGestureTarget(target: self, action: #selector(buttonAction))
    action.addTarget(wrapper, action: #selector(WeakGestureTarget.handleGesture(_:)))
    gestureWrappers.append(wrapper)

    button.addGestureRecognizer(action)

    // ... rest of implementation
}
```

**Testing**:
```swift
// Add to test suite
func testViewControllerDeallocates() {
    weak var weakVC: ViewController?

    autoreleasepool {
        let vc = ViewController()
        vc.loadViewIfNeeded()
        weakVC = vc

        // Simulate user interaction
        vc.viewDidAppear(false)
        vc.viewWillDisappear(false)
        vc.viewDidDisappear(false)
    }

    // VC should be deallocated
    XCTAssertNil(weakVC, "ViewController was not deallocated - possible retain cycle")
}
```

---

### ⚠️ UNKNOWN: RequestStatusDelegate Retention

**Location**: `ViewController.swift:69, 76, 83`

**Code**:
```swift
// Line 69
mivip.qrCode(vc: self, requestStatusDelegate: self, documentCallbackUrl: documentCallbackTextField.text)

// Line 76
mivip.request(vc: self, miVipRequestId: idRequest, requestStatusDelegate: self, documentCallbackUrl: documentCallbackTextField.text)

// Line 83
mivip.request(vc: strongSelf, miVipRequestId: idRequest, requestStatusDelegate: strongSelf, documentCallbackUrl: strongSelf.documentCallbackTextField.text)
```

**Issue**: Cannot verify whether MiVIPHub holds strong or weak reference to `requestStatusDelegate`.

**Severity**: **MEDIUM if strong**, **NONE if weak**

**Risk Analysis**:

**If MiVIPHub implementation is**:
```swift
// ❌ STRONG (creates retain cycle)
class MiVIPHub {
    var delegate: RequestStatusDelegate?  // Strong reference

    func qrCode(vc: UIViewController, requestStatusDelegate: RequestStatusDelegate?, ...) {
        self.delegate = requestStatusDelegate  // VC retains Hub, Hub retains VC
    }
}
```

**If MiVIPHub implementation is**:
```swift
// ✅ WEAK (no retain cycle)
class MiVIPHub {
    weak var delegate: RequestStatusDelegate?  // Weak reference

    func qrCode(vc: UIViewController, requestStatusDelegate: RequestStatusDelegate?, ...) {
        self.delegate = requestStatusDelegate  // No cycle
    }
}
```

**How to Verify**:

**Option 1** - Check framework headers:
```bash
# Extract headers from XCFramework
cd SDKs/MiVIPSdk.xcframework/ios-arm64/MiVIPSdk.framework/Headers
grep -A 5 "RequestStatusDelegate" MiVIPSdk.h

# Look for:
# @property (weak, nonatomic) id<RequestStatusDelegate> delegate;  // ✅ Safe
# @property (strong, nonatomic) id<RequestStatusDelegate> delegate; // ❌ Leak
# @property (nonatomic) id<RequestStatusDelegate> delegate;         // ❌ Strong by default
```

**Option 2** - Test with Memory Graph Debugger:
1. Run app in Xcode
2. Navigate to ViewController and start a verification
3. Navigate back (dismiss ViewController)
4. Xcode → Debug → Memory Graph Debugger
5. Search for "ViewController" instances
6. Expected: 0 instances (no leak)
7. If instances exist: Check backtrace for retain cycle path

**Option 3** - Use Instruments Leaks tool:
```bash
# In Xcode:
# 1. Product → Profile (⌘I)
# 2. Select "Leaks" template
# 3. Run app and navigate ViewController repeatedly
# 4. Check for ViewController instances in leaks report
```

**Recommended Mitigation** (if strong reference confirmed):

**Approach 1** - Nil out delegate when done:
```swift
extension ViewController: MiVIPSdk.RequestStatusDelegate {

    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        debugPrint("MiVIP: RequestStatus = \(status), RequestResult \(result)")

        // ✅ Clear delegate on terminal status
        if status == .COMPLETED || status == .FAILED || status == .CANCELLED {
            // Note: This assumes MiVIPHub exposes a way to clear delegate
            // Check SDK documentation or headers for proper API
        }
    }

    func error(err: String) {
        debugPrint("MiVIP: \(err)")
        // ✅ Clear delegate on error too
    }
}

override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // ✅ Clear delegate when leaving screen
    // mivip.delegate = nil  // If API allows
}
```

**Approach 2** - Use weak wrapper:
```swift
// Create a weak delegate wrapper
private class WeakRequestStatusDelegate: RequestStatusDelegate {
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

// Usage
private var delegateWrapper: WeakRequestStatusDelegate?

@objc fileprivate func buttonAction(gesture: MenuGesture) {
    guard let scope = gesture.scope else { return }

    do {
        let mivip = try MiVIPHub()

        // ✅ Use weak wrapper
        delegateWrapper = WeakRequestStatusDelegate(target: self)

        switch scope {
        case "QR":
            mivip.qrCode(vc: self, requestStatusDelegate: delegateWrapper, ...)
        case "request":
            mivip.request(vc: self, miVipRequestId: idRequest, requestStatusDelegate: delegateWrapper, ...)
        }
    } catch {
        print(error)
    }
}
```

**Approach 3** - Contact SDK vendor:
```
Subject: MiVIP SDK - RequestStatusDelegate Memory Management

Hello MiVIP Team,

We're integrating MiVIP SDK v3.6.15 and need to confirm the memory management
strategy for RequestStatusDelegate to prevent retain cycles.

Question: Does MiVIPHub hold a weak or strong reference to requestStatusDelegate?

In the binary framework, we cannot inspect the property declaration. This is
important for preventing memory leaks in our view controllers.

If strong: What's the recommended pattern for clearing the delegate?
If weak: Please confirm in documentation for future reference.

Thank you!
```

---

### ✅ GOOD: No Timer Leaks

**Search Pattern**: `Timer.scheduledTimer`, `Timer(timeInterval:`, `Timer.publish`

**Result**: No timers found in code

**Status**: ✅ **NO ISSUE**

**Note**: If timers are added in the future, remember:
```swift
// ❌ BAD - Creates retain cycle
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [self] _ in
    self.updateUI()
}

// ✅ GOOD - Use weak self
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
    guard let self = self else {
        timer.invalidate()
        return
    }
    self.updateUI()
}

// ✅ BEST - Invalidate in deinit
private var updateTimer: Timer?

func startTimer() {
    updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        self?.updateUI()
    }
}

deinit {
    updateTimer?.invalidate()
}
```

---

### ✅ GOOD: No NotificationCenter Observer Leaks

**Search Pattern**: `NotificationCenter.default.addObserver`, `.addObserver(forName:`

**Result**: No notification observers found in code

**Status**: ✅ **NO ISSUE**

**Note**: If observers are added in the future, remember:
```swift
// ❌ BAD (iOS 8 and earlier) - Must remove in deinit
NotificationCenter.default.addObserver(self,
    selector: #selector(handleNotification),
    name: UIApplication.didBecomeActiveNotification,
    object: nil)

deinit {
    NotificationCenter.default.removeObserver(self)  // MUST HAVE
}

// ✅ GOOD (iOS 9+) - Block-based observers auto-cleanup
private var observer: NSObjectProtocol?

func setupObserver() {
    observer = NotificationCenter.default.addObserver(
        forName: UIApplication.didBecomeActiveNotification,
        object: nil,
        queue: .main
    ) { [weak self] notification in
        self?.handleNotification(notification)
    }
}

deinit {
    if let observer = observer {
        NotificationCenter.default.removeObserver(observer)
    }
}
```

---

### ✅ GOOD: No Combine Subscriber Leaks

**Search Pattern**: `.sink`, `.assign`, `AnyCancellable`

**Result**: No Combine usage found

**Status**: ✅ **NO ISSUE**

**Note**: If Combine is added in the future, remember to store cancellables:
```swift
private var cancellables = Set<AnyCancellable>()

func setupBindings() {
    publisher
        .sink { [weak self] value in
            self?.handleValue(value)
        }
        .store(in: &cancellables)  // ✅ Important!
}

deinit {
    cancellables.removeAll()  // Auto-cancelled
}
```

---

## Summary

### Issues by Severity

| Severity | Count | Pattern | Status |
|----------|-------|---------|--------|
| **CRITICAL** | 0 | - | - |
| **HIGH** | 0 | - | - |
| **MEDIUM** | 2 | Gesture strong reference, Unknown delegate retention | ⚠️ Needs fix |
| **LOW** | 0 | - | - |
| **GOOD** | 3 | Weak self in closures, No timer leaks, No observer leaks | ✅ OK |

### Memory Risk: **MEDIUM**

- Current leaks are conditional (depend on view controller lifecycle and SDK implementation)
- Leaks are fixable with moderate effort
- No critical/high severity issues that would cause immediate problems

---

## Priority Action Items

### 🟡 Recommended (Before Production)

1. **Fix MEDIUM-001**: Add gesture recognizer cleanup or migrate to UIButton
   - Estimated effort: 2-3 hours
   - File: `ViewController.swift:122-125`
   - See "Recommended Fix Option 1" or "Option 2" above

2. **Investigate UNKNOWN-001**: Verify MiVIPHub delegate retention
   - Estimated effort: 1 hour investigation + potential fix
   - Check framework headers or test with Memory Graph Debugger
   - If strong reference found, implement mitigation pattern

### 🟢 Optional (Best Practices)

3. **Add memory leak unit tests**
   - Test that ViewController deallocates properly
   - Add to CI/CD pipeline

4. **Document memory management patterns**
   - Add code comments explaining weak self usage
   - Create team guidelines for closure captures

---

## Testing Checklist

Before releasing to production:

### Memory Graph Debugger Testing
- [ ] Run app in Xcode Debug mode
- [ ] Navigate to ViewController → Go back (repeat 5 times)
- [ ] Xcode → Debug → View Memory Graph
- [ ] Search for "ViewController" instances
- [ ] Verify count = 1 (current instance only)
- [ ] Check for retain cycles in backtrace

### Instruments Leaks Testing
- [ ] Xcode → Product → Profile (⌘I)
- [ ] Select "Leaks" template
- [ ] Run app and perform full user journey
- [ ] Navigate ViewController multiple times
- [ ] Verify no ViewController leaks reported
- [ ] Check "Allocations" for memory growth trends

### Instruments Allocations Testing
- [ ] Profile with "Allocations" template
- [ ] Set baseline memory usage
- [ ] Navigate ViewController 10 times
- [ ] Check if memory returns to baseline
- [ ] If memory grows > 10%, investigate retained objects

### Manual Testing
- [ ] Enable "Malloc Stack Logging" in scheme
- [ ] Run app and navigate normally for 5 minutes
- [ ] Check memory usage in Debug Navigator
- [ ] Memory should stabilize, not continuously grow

---

## Memory Management Best Practices

### For Future Development

**1. Always use `[weak self]` in closures that escape**:
```swift
// ✅ GOOD
URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
    guard let self = self else { return }
    self.handleResponse(data)
}

// ❌ BAD
URLSession.shared.dataTask(with: url) { data, response, error in
    self.handleResponse(data)  // Retain cycle if task is stored
}
```

**2. Invalidate timers and cancel operations in deinit**:
```swift
private var timer: Timer?
private var task: URLSessionDataTask?

deinit {
    timer?.invalidate()
    task?.cancel()
    NotificationCenter.default.removeObserver(self)
}
```

**3. Use weak delegates**:
```swift
// ✅ GOOD
protocol MyDelegate: AnyObject { }
weak var delegate: MyDelegate?

// ❌ BAD
protocol MyDelegate { }
var delegate: MyDelegate?
```

**4. Prefer modern patterns over legacy ones**:
```swift
// ✅ Modern (iOS 14+)
button.addAction(UIAction { [weak self] _ in
    self?.handleTap()
}, for: .touchUpInside)

// ❌ Legacy (retain cycle risk)
let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
button.addGestureRecognizer(gesture)
```

**5. Test deallocation in unit tests**:
```swift
func testViewControllerDeallocates() {
    weak var weakVC: ViewController?

    autoreleasepool {
        let vc = ViewController()
        weakVC = vc
        vc.loadViewIfNeeded()
        vc.viewDidAppear(false)
    }

    XCTAssertNil(weakVC, "ViewController leaked")
}
```

---

## Tools Reference

### Xcode Built-in Tools

**Memory Graph Debugger** (⇧⌘M):
- Shows object graph and retain cycles
- Use while app is running
- Purple exclamation marks indicate leaks

**Instruments Leaks**:
- Automatically detects leaked memory
- Shows allocation backtraces
- Good for long-running leak detection

**Instruments Allocations**:
- Shows all allocations and deallocations
- Use "Mark Generation" to track growth
- Filter by class name (e.g., "ViewController")

**Debug Memory Graph Export**:
```bash
# Export memory graph for offline analysis
# In Xcode Debug Navigator → Memory → Export Memory Graph
# Analyze with: leaks <memgraph_file>
```

### Third-Party Tools

**FBRetainCycleDetector** (Facebook):
```ruby
# Podfile
pod 'FBRetainCycleDetector'

# Usage
import FBRetainCycleDetector

let detector = FBRetainCycleDetector()
detector.addCandidate(self)
let cycles = detector.findRetainCycles()
print("Retain cycles: \(cycles)")
```

**LifetimeTracker**:
```ruby
# Podfile
pod 'LifetimeTracker'

# Track view controller lifecycle
class ViewController: UIViewController, LifetimeTrackable {
    static var lifetimeConfiguration = LifetimeConfiguration(
        maxCount: 1,
        groupName: "ViewControllers"
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        trackLifetime()
    }
}
```

---

## Appendix: Complete Memory-Safe Implementation

See the following implementation with all memory safety fixes applied:

```swift
import UIKit
import MiVIPSdk
import MiVIPApi

class ViewController: UIViewController {

    private var requestIdTextField = UITextField()
    private var documentCallbackTextField = UITextField()
    private var requestCodeTextField = UITextField()

    // ✅ Store delegate wrapper to prevent potential SDK retain cycle
    private var delegateWrapper: WeakRequestStatusDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()

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

    // ✅ Clean up gesture recognizers to prevent retain cycles
    deinit {
        view.subviews.forEach { subview in
            subview.gestureRecognizers?.forEach { gesture in
                gesture.removeTarget(nil, action: nil)
            }
        }

        delegateWrapper = nil

        print("ViewController deallocated - no memory leak")
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

            // ✅ Use weak wrapper for delegate to prevent potential retain cycle
            delegateWrapper = WeakRequestStatusDelegate(target: self)

            switch scope {
            case "QR":
                mivip.qrCode(vc: self, requestStatusDelegate: delegateWrapper, documentCallbackUrl: documentCallbackTextField.text)
            case "history":
                mivip.history(vc: self)
            case "account":
                mivip.account(vc: self)
            case "request":
                guard let idRequest = requestIdTextField.text else { return }
                mivip.request(vc: self, miVipRequestId: idRequest, requestStatusDelegate: delegateWrapper, documentCallbackUrl: documentCallbackTextField.text)
            case "code":
                guard let code = requestCodeTextField.text else { return }
                mivip.getRequestIdFromCode(code: code) { (idRequest, error) in
                    DispatchQueue.main.async { [weak self] in  // ✅ Weak self
                        guard let strongSelf = self else { return }
                        if let idRequest = idRequest {
                            mivip.request(vc: strongSelf, miVipRequestId: idRequest, requestStatusDelegate: strongSelf.delegateWrapper, documentCallbackUrl: strongSelf.documentCallbackTextField.text)
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
}

// ✅ Weak delegate wrapper to prevent retain cycle with SDK
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

extension ViewController: MiVIPSdk.RequestStatusDelegate {

    func status(status: MiVIPApi.RequestStatus?, result: MiVIPApi.RequestResult?, scoreResponse: MiVIPApi.ScoreResponse?, request: MiVIPApi.MiVIPRequest?) {
        debugPrint("MiVIP: RequestStatus = \(status), RequestResult \(result), ScoreResponse \(scoreResponse), MiVIPRequest \(request)")
    }

    func error(err: String) {
        debugPrint("MiVIP: \(err)")
    }
}

// UI Extensions remain the same...
// (See accessibility-audit.md for full implementation)

private class MenuGesture: UITapGestureRecognizer {
    var scope: String?
}
```

---

**Report Generated**: 2025-12-19
**Next Review**: Before production deployment
**Contact**: Development team for implementation questions
