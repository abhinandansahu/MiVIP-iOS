# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

MiVIP SDK v3.6.15 for iOS - A fully orchestrated identity verification SDK that combines Mitek's MiSnap capture technology with a pre-built dynamic user journey. This is an SDK distribution repository containing pre-compiled XCFrameworks, not source code.

**Key Components:**
- **MiVIPApi.xcframework** - API calls and result handling
- **MiVIPLiveness.xcframework** - Active liveness implementation
- **MiVIPSdk.xcframework** - Journey orchestration and UI
- **Examples/** - Sample integration apps (whitelabel_demo, ios-webviewdemo)
- **SDKs/** - Pre-compiled binary frameworks

## System Requirements

- **Xcode:** 15.0+
- **iOS:** 13.0+
- **Swift:** 5.5+
- **MiSnap:** 5.9.1 (required dependency)

## Build & Run Commands

### Example Apps

**Build whitelabel_demo:**
```bash
cd Examples/whitelabel_demo
pod install
open whitelabel_demo.xcworkspace
# Build in Xcode (Cmd+B) or run (Cmd+R)
```

**Update pod version:**
```bash
cd Examples/whitelabel_demo
pod update MiVIP
```

### Swift Package Manager

This repository is SPM-compatible via Package.swift. No build commands needed - consumers add as dependency.

## Architecture

### Example App Architecture (MVVM-C)

**Introduced in v3.6.15** - The `whitelabel_demo` has been refactored from a monolithic ViewController into a modern **MVVM-C (Model-View-ViewModel-Coordinator)** architecture.

#### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        SceneDelegate                             │
│                             │                                    │
│                    ┌────────▼────────┐                          │
│                    │ DependencyContainer │ ◄── Singleton DI     │
│                    └────────┬────────┘                          │
│                             │                                    │
│                    ┌────────▼────────┐                          │
│                    │  AppCoordinator  │ ◄── App-level nav       │
│                    └────────┬────────┘                          │
│                             │                                    │
│              ┌──────────────▼──────────────┐                    │
│              │      MiVIPCoordinator       │ ◄── Route handling │
│              │  (uses MiVIPRoute enum)     │                    │
│              └──────────────┬──────────────┘                    │
│                             │                                    │
│    ┌────────────────────────┼────────────────────────┐          │
│    │                        │                        │          │
│    ▼                        ▼                        ▼          │
│ ┌──────────┐        ┌──────────────┐        ┌──────────────┐   │
│ │ViewController │◄──│ MiVIPHubViewModel │──►│ MiVIPService │   │
│ │  (View)   │        │ (@Published)  │        │ (Protocol)  │   │
│ └──────────┘        └──────────────┘        └──────┬───────┘   │
│                                                     │           │
│                                              ┌──────▼───────┐   │
│                                              │  MiVIPHub    │   │
│                                              │ (SDK Binary) │   │
│                                              └──────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

#### Core Components (in ViewController.swift)

| Component | Purpose |
|-----------|---------|
| **DependencyContainer** | Singleton managing service initialization with license debugging |
| **AppCoordinator** | App-level navigation, owns the window and router |
| **AppRouter** | Abstraction over UINavigationController |
| **MiVIPCoordinator** | Handles SDK flow routes via `MiVIPRoute` enum |
| **MiVIPHubViewModel** | State management with Combine `@Published` properties |
| **MiVIPService** | Protocol-based SDK wrapper with async/await support |
| **MiVIPServiceFallback** | Graceful degradation when license validation fails |
| **MiVIPRoute** | Type-safe enum for navigation (.qr, .request, .code, .history, .account) |

#### Key Patterns

**Combine Reactive Bindings:**
```swift
viewModel.$requestState
    .receive(on: RunLoop.main)
    .sink { [weak self] state in
        switch state {
        case .loading: self?.loading.startAnimating()
        case .success(let res): self?.alert("Success", "Result: \(res)")
        case .failure(let err): self?.alert("Error", err.userMessage)
        default: self?.loading.stopAnimating()
        }
    }.store(in: &cancellables)
```

**Route-Based Navigation:**
```swift
enum MiVIPRoute {
    case qr(String?)
    case request(id: String, url: String?)
    case code(code: String, url: String?)
    case history
    case account
}

// Usage
coordinator.coordinate(to: .qr(callbackURL))
coordinator.coordinate(to: .request(id: "uuid", url: nil))
```

**Fallback Service Pattern:**
```swift
// In DependencyContainer
do {
    self.mivipService = try MiVIPService()
} catch {
    // Graceful degradation - shows alerts instead of crashing
    self.mivipService = MiVIPServiceFallback(error: error)
}
```

### SDK Distribution Model

This is a **binary framework distribution repository**. The actual SDK implementation is compiled into XCFrameworks in `SDKs/`. You cannot modify SDK behavior directly - only configure it via:

1. **Info.plist** configuration (backend URL, colors, logo)
2. **MiVIPHub API** at runtime (fonts, sounds, wallet)
3. **Custom assets** (override SDK icons/images in consuming app)
4. **Localization** (override SDK strings via Localizable.strings)

### Integration Flow

```
Consumer App → MiVIPHub() → MiVIPSdk.xcframework
                 ↓
            MiVIPApi.xcframework (API communication)
                 ↓
            MiVIPLiveness.xcframework (biometric)
                 ↓
            MiSnap SDKs (document capture)
```

### Key SDK Entry Points

**MiVIPHub** (from MiVIPSdk) - Main SDK controller:
- `qrCode(vc:requestStatusDelegate:documentCallbackUrl:)` - Start with QR scan
- `request(vc:miVipRequestId:requestStatusDelegate:documentCallbackUrl:)` - Open specific request
- `history(vc:)` - Show request history
- `account(vc:)` - Show wallet/stored identity
- `getRequestIdFromCode(code:completion:)` - Convert 4-digit code to request ID

**RequestStatusDelegate** - Callback interface for request lifecycle:
- `status(status:result:scoreResponse:request:)` - Status updates
- `error(err:)` - Error notifications

### Configuration Architecture

**3-tier customization priority:**
1. Business console settings (highest - fetched from backend)
2. Info.plist values (medium - app bundle)
3. SDK defaults (lowest)

**Required Info.plist keys:**
- `HOOYU_API_URL` - MiVIP backend instance URL

**Optional Info.plist keys:**
- `logo_image` - Asset catalog name for company logo
- Color keys: `main_color`, `header_color`, `alert_color`, `button_gradirn_start_color`, `button_gradirn_end_color`, `button_text_color`, `menu_item_background`

**NFC Configuration** (if using document NFC reading):
- Add "Near Field Communication Tag Reading" capability in Xcode
- Add CoreNFC.framework
- Configure `com.apple.developer.nfc.readersession.iso7816.select-identifiers` in Info.plist
- Configure `com.apple.developer.nfc.readersession.felica.systemcodes` in Info.plist
- Entitlements: `com.apple.developer.nfc.readersession.formats` = `["TAG"]`

**Permission requirements:**
- Camera (NSCameraUsageDescription) - for document/face capture
- Microphone (NSMicrophoneUsageDescription) - for voice sessions
- Location (NSLocationWhenInUseUsageDescription) - optional anti-fraud control

### Example App Structure

The `whitelabel_demo` follows MVVM-C architecture with all core components defined inline in `ViewController.swift` for simplicity:

**File: `Examples/whitelabel_demo/whitelabel_demo/ViewController.swift`**

| Section | Lines | Components |
|---------|-------|------------|
| Models & Errors | 6-22 | `MiVIPRequestState`, `MiVIPError` |
| Protocols | 24-32 | `MiVIPServiceProtocol`, `RequestStatusDelegate` |
| Dependency Injection | 34-69 | `DependencyContainer` (singleton with license debugging) |
| Navigation (MVVM-C) | 71-154 | `Coordinator`, `Router`, `AppCoordinator`, `MiVIPCoordinator`, `MiVIPRoute` |
| View Model | 156-167 | `MiVIPHubViewModel` with `@Published` state |
| Services | 169-209 | `MiVIPService`, `MiVIPServiceFallback` |
| Views | 211-227 | `PrimaryButton` with iOS 15+ configuration |
| View Controller | 229-327 | Main UI with Combine bindings |

**Supporting Files:**

| Directory | Files | Purpose |
|-----------|-------|---------|
| `Config/` | `Config.xcconfig` | Externalized API URL and license key |
| `Configuration/` | `SecureConfiguration.swift` | License key accessor |
| `Theming/` | `ColorPalette.swift` | Dark mode semantic colors |
| `Views/` | `LoadingView.swift`, `PrimaryButton.swift` | Reusable accessible components |
| `Security/` | `BiometricAuthentication.swift`, `PrivacyScreenService.swift` | FaceID/TouchID, app background blur |
| `Errors/` | `MiVIPError.swift` | Typed error handling |
| `Models/` | `MiVIPRequestState.swift` | Request lifecycle states |

**Entry Point:** `SceneDelegate.swift` initializes `AppCoordinator` with `DependencyContainer.shared`

## Installation Methods

### CocoaPods (Recommended for quick start)
```ruby
pod 'MiVIP', '3.6.15'
```
Automatically pulls MiSnap dependencies.

### Swift Package Manager
Add package: `https://github.com/Mitek-Systems/MiVIP-iOS`
Manually add MiSnap SDKs and SocketRocket 0.6.1.

### Manual
1. Add MiSnap SDKs first
2. Drag MiVIP XCFrameworks from `SDKs/` to Xcode
3. Set "Embed & Sign" for all frameworks
4. Install dependencies via CocoaPods (see Podfile in example)

## Important Notes

- **License requirement:** MiSnap license key must be configured before using SDK (see MiSnap-iOS repository)
- **Binary-only:** Source code is not available - SDK behavior modified only through configuration
- **Size impact:** ~13.7MB compressed download size, ~17.2MB installed
- **Dependencies:** Requires SocketRocket (0.6.1) for WebSocket communication
- **Custom fonts:** Import fonts → add to Info.plist UIAppFonts → set via MiVIPHub setters
- **Custom icons:** Add identically-named assets to consuming app's Assets.xcassets to override SDK icons
- **Localization:** Override SDK strings by defining same keys in app's Localizable.strings

## ✅ Code Quality Status (v3.6.15)

**Architecture refactored in v3.6.15** - The comprehensive audits identified issues that have been addressed:

### Resolved Issues

| Issue | Severity | Resolution |
|-------|----------|------------|
| Non-accessible UI controls | 🚨 CRITICAL | ✅ Replaced UIView+gesture with `PrimaryButton` (UIButton subclass) |
| Missing Dynamic Type | 🚨 CRITICAL | ✅ `UIFont.preferredFont(forTextStyle:)` with `adjustsFontForContentSizeCategory` |
| Missing VoiceOver labels | ⚠️ HIGH | ✅ Text fields have proper placeholders; buttons are native UIButton |
| Gesture recognizer retain cycles | ⚠️ MEDIUM | ✅ Eliminated by migrating to UIButton with target-action |
| SDK delegate retention | ⚠️ MEDIUM | ✅ ViewModel is `NSObject` subclass, properly managed by Coordinator |

### Architecture Improvements

- **MVVM-C Pattern**: Clear separation of concerns
- **Combine Bindings**: Reactive state updates without retain cycles
- **Protocol Abstraction**: `MiVIPServiceProtocol` enables testing
- **Fallback Service**: Graceful degradation on license errors
- **Auto Layout**: Replaced manual frame calculations with constraints

### Remaining Considerations

⚠️ **Test Synchronization Needed**: Unit tests in `whitelabel_demoTests/` reference an older `MiVIPServiceProtocol` signature. Tests need updating to match the current inline architecture.

See audit reports for historical context:
- **[Accessibility Audit](Docs/accessibility-audit.md)** - Original findings (now resolved)
- **[Memory Leak Audit](Docs/memory-audit.md)** - Original findings (now resolved)

## Unit Testing

**Test Target:** `whitelabel_demoTests`

### Test Files

| File | Tests |
|------|-------|
| `ViewModelTests/MiVIPHubViewModelTests.swift` | ViewModel state transitions, delegate callbacks |
| `ServiceTests/MiVIPServiceTests.swift` | Service method invocation verification |

### Running Tests

```bash
cd Examples/whitelabel_demo
xcodebuild test -workspace whitelabel_demo.xcworkspace -scheme whitelabel_demo -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Mock Service

```swift
class MockMiVIPService: MiVIPServiceProtocol {
    var qrCodeScanCalled = false
    var openRequestCalled = false
    // ... tracking properties for verification
}
```

### ⚠️ Test Maintenance Note

The tests were written against an earlier version of `MiVIPServiceProtocol`. The current protocol in `ViewController.swift` uses:
- `getRequestId(from:) async throws -> String?` (async/await)

While the tests expect:
- `openRequestByCode(vc:code:delegate:callbackURL:completion:)` (callback-based)

**Action Required:** Update `MockMiVIPService` and tests to match current protocol signature.

## Common Integration Issues

1. **MiSnap license errors:** Ensure valid MiSnap license configured before initializing MiVIPHub
2. **Missing NFC entitlements:** If using document NFC, verify all entitlement arrays and capability are set
3. **Framework embedding:** All XCFrameworks must be "Embed & Sign" not "Do Not Embed"
4. **Info.plist URL:** `HOOYU_API_URL` must point to correct MiVIP backend instance
5. **Font loading:** Custom fonts must be declared in Info.plist UIAppFonts before calling setFont methods
6. **Accessibility in custom UI:** When creating custom UI that integrates with SDK, ensure full VoiceOver support (see accessibility audit)
7. **Memory management with delegates:** Use weak references or weak wrappers when implementing RequestStatusDelegate (see memory audit)

## Best Practices for Integration

### Architecture Patterns (Demonstrated in whitelabel_demo)

1. **Use MVVM-C for navigation-heavy apps**
   - Coordinators own navigation logic
   - ViewModels expose `@Published` state
   - Views subscribe via Combine

2. **Abstract SDK behind protocols**
   ```swift
   protocol MiVIPServiceProtocol {
       func startQRCodeScan(vc: UIViewController, delegate: RequestStatusDelegate, callbackURL: String?)
       // ... other methods
   }
   ```

3. **Implement fallback services for graceful degradation**
   ```swift
   class MiVIPServiceFallback: MiVIPServiceProtocol {
       let error: Error
       func startQRCodeScan(...) { showErrorAlert() }
   }
   ```

4. **Use DependencyContainer for testability**
   ```swift
   class DependencyContainer {
       static let shared = DependencyContainer()
       let mivipService: MiVIPServiceProtocol
   }
   ```

### UI/UX Guidelines

- Use `PrimaryButton` (UIButton subclass) for all interactive elements
- Support Dark Mode via `ColorPalette` semantic colors
- Enable Dynamic Type with `adjustsFontForContentSizeCategory = true`
- Add `PrivacyScreenService` blur when app backgrounds

### Security

- Externalize license keys to `Config.xcconfig` (gitignored)
- Use `BiometricAuthentication` for sensitive screens
- Validate license at startup with detailed diagnostics

**Key Guidelines:**
- Use UIButton (not UIView) for interactive elements - ensures VoiceOver accessibility
- Support Dynamic Type with `UIFont.preferredFont(forTextStyle:)` and `adjustsFontForContentSizeCategory = true`
- Add `accessibilityLabel` and `accessibilityHint` to all interactive UI elements
- Use weak delegate wrappers when implementing RequestStatusDelegate to prevent retain cycles
- Clean up gesture recognizers in `deinit` to prevent memory leaks
- Test with VoiceOver, Dynamic Type (max size), and Memory Graph Debugger

See audit reports for detailed code examples and testing procedures.

## Reference Documentation

- **Integration guide:** `Docs/dev_guide_ios.md`
- **Architecture documentation:** `Docs/Architecture.md`
- **Accessibility audit:** `Docs/accessibility-audit.md` (⚠️ Read before App Store submission)
- **Memory leak audit:** `Docs/memory-audit.md` (⚠️ Read before production)
- **Improvement plan:** `Docs/plan.md` (Complete roadmap to production-ready code)
- **Third-party licenses:** `Docs/3rd_party_licensing_info.md`
- **MiSnap integration:** https://github.com/Mitek-Systems/MiSnap-iOS
