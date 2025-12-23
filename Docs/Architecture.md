# MiVIP-iOS Architecture Documentation

**Version:** 3.6.15  
**Last Updated:** December 2025  
**Architecture Pattern:** MVVM-C (Model-View-ViewModel-Coordinator)

---

## Overview

The `whitelabel_demo` application was refactored in **v3.6.15** from a monolithic Storyboard-based MVC implementation into a modern **MVVM-C architecture**. This transformation ensures:

- ✅ **Testability** - Protocol-based services enable mocking
- ✅ **Maintainability** - Clear separation of concerns
- ✅ **Accessibility** - Native UIButton controls with Dynamic Type
- ✅ **Resilience** - Fallback service for license failures
- ✅ **Reactivity** - Combine-based state management

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              SceneDelegate                               │
│                                    │                                     │
│                         ┌──────────▼──────────┐                         │
│                         │ DependencyContainer │                         │
│                         │     (Singleton)     │                         │
│                         └──────────┬──────────┘                         │
│                                    │ creates                            │
│                         ┌──────────▼──────────┐                         │
│                         │   AppCoordinator    │                         │
│                         │   (owns window)     │                         │
│                         └──────────┬──────────┘                         │
│                                    │ starts                             │
│                         ┌──────────▼──────────┐                         │
│                         │  MiVIPCoordinator   │                         │
│                         │ (route handling)    │                         │
│                         └──────────┬──────────┘                         │
│                                    │                                     │
│         ┌──────────────────────────┼──────────────────────────┐         │
│         │                          │                          │         │
│         ▼                          ▼                          ▼         │
│   ┌───────────┐          ┌─────────────────┐         ┌──────────────┐  │
│   │ViewController │◄────│ MiVIPHubViewModel │────────►│ MiVIPService │  │
│   │   (View)   │  binds  │  (@Published)   │  calls   │  (Protocol)  │  │
│   └───────────┘          └─────────────────┘         └───────┬──────┘  │
│                                                              │         │
│                                                    ┌─────────▼────────┐│
│                                                    │    MiVIPHub      ││
│                                                    │  (SDK Binary)    ││
│                                                    └──────────────────┘│
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Component Details

### 1. DependencyContainer (Lines 36-69 in ViewController.swift)

Singleton responsible for:
- License key validation and debugging
- Service initialization with error handling
- Factory methods for ViewModels

```swift
class DependencyContainer {
    static let shared = DependencyContainer()
    let mivipService: MiVIPServiceProtocol
    
    init() {
        // Detailed license debugging output
        do {
            self.mivipService = try MiVIPService()
        } catch {
            self.mivipService = MiVIPServiceFallback(error: error)
        }
    }
}
```

### 2. Coordinators (Lines 71-154)

#### AppCoordinator
- Owns the `UIWindow`
- Creates the root navigation via `AppRouter`
- Manages child coordinators

#### MiVIPCoordinator
- Handles all MiVIP SDK navigation flows
- Uses type-safe `MiVIPRoute` enum
- Delegates SDK calls to ViewModel

```swift
enum MiVIPRoute {
    case qr(String?)                        // QR code scanning
    case request(id: String, url: String?)  // Direct request by ID
    case code(code: String, url: String?)   // Request by 4-digit code
    case history                            // Request history
    case account                            // Wallet/account
}
```

### 3. MiVIPHubViewModel (Lines 156-167)

- Inherits from `NSObject` to conform to `RequestStatusDelegate`
- Exposes `@Published var requestState: MiVIPRequestState`
- Handles SDK delegate callbacks

**State Machine:**
```
idle ──► loading ──► success(RequestResult)
              │
              └──► failure(MiVIPError)
```

### 4. Services (Lines 169-209)

#### MiVIPService
- Wraps `MiVIPHub` with protocol abstraction
- Configures SDK (sounds, fonts)
- Provides async/await wrapper for code-to-ID resolution

#### MiVIPServiceFallback
- Activated when SDK initialization fails
- Shows user-friendly error alerts
- Prevents app crashes from license issues

### 5. Router (Lines 78-88)

```swift
protocol Router: AnyObject {
    var navigationController: UINavigationController { get }
    func setRootViewController(_ viewController: UIViewController, animated: Bool)
}
```

Abstracts navigation for testability.

---

## Data Flow

### Request Lifecycle

```
1. User taps button
       │
       ▼
2. ViewController calls coordinator.coordinate(to: .qr(url))
       │
       ▼
3. MiVIPCoordinator sets viewModel.requestState = .loading
       │
       ▼
4. MiVIPCoordinator calls mivipService.startQRCodeScan()
       │
       ▼
5. MiVIPService invokes mivipHub.qrCode(vc:delegate:...)
       │
       ▼
6. SDK presents QR scanner UI
       │
       ▼
7. SDK calls delegate.status() or delegate.error()
       │
       ▼
8. MiVIPHubViewModel updates @Published requestState
       │
       ▼
9. ViewController receives state via Combine subscription
       │
       ▼
10. UI updates (hides loading, shows result/error)
```

---

## Key Learnings & Resolutions

### 1. Git LFS Issues with SPM
**Problem:** MiSnap SPM repository uses Git LFS for binaries, causing "Missing module" errors.  
**Resolution:** Use CocoaPods for reliable binary framework consumption.

### 2. Xcode 16 Binary Compatibility
**Problem:** Frameworks built without `BUILD_LIBRARY_FOR_DISTRIBUTION` cause module stability errors.  
**Resolution:** Pin Swift version to 5.10; let CocoaPods manage framework paths.

### 3. License Key Binding
**Problem:** License keys are cryptographically bound to Bundle ID; mismatches cause silent failures.  
**Resolution:** Implemented `MiVIPServiceFallback` with detailed console diagnostics.

---

## File Structure

```
whitelabel_demo/
├── ViewController.swift          # All MVVM-C components (inline)
├── SceneDelegate.swift           # App entry, coordinator setup
├── AppDelegate.swift             # App lifecycle
├── Config/
│   └── Config.xcconfig           # API URL, license key
├── Configuration/
│   └── SecureConfiguration.swift # License key accessor
├── Theming/
│   └── ColorPalette.swift        # Dark mode colors
├── Views/
│   ├── LoadingView.swift         # Accessible loading overlay
│   └── PrimaryButton.swift       # Reusable button component
├── Security/
│   ├── BiometricAuthentication.swift
│   └── PrivacyScreenService.swift
├── Errors/
│   └── MiVIPError.swift
├── Models/
│   └── MiVIPRequestState.swift
└── (Legacy directories - may contain duplicates)
    ├── Coordinators/
    ├── ViewModels/
    └── Services/
```

> **Note:** The `Coordinators/`, `ViewModels/`, and `Services/` directories contain earlier implementations. The canonical architecture is defined inline in `ViewController.swift`.

---

## Testing

### Test Structure
```
whitelabel_demoTests/
├── ViewModelTests/
│   └── MiVIPHubViewModelTests.swift
└── ServiceTests/
    └── MiVIPServiceTests.swift
```

### ⚠️ Test Synchronization Required
Tests reference an older protocol signature with callback-based APIs. Current architecture uses async/await. Tests require updating to match.

---

## Future Roadmap

### Phase 1: SwiftUI Migration
- Replace UIKit ViewController with SwiftUI views
- Leverage existing ViewModels with `@StateObject`
- Implement dynamic theming system

### Phase 2: Security Hardening
- SSL certificate pinning for all traffic
- Biometric protection for sensitive screens
- App Attest/DeviceCheck integration

### Phase 3: Modularization
- Extract services into local Swift Package
- Automated license key rotation via CI/CD
- Multi-app SDK integration template

---

## References

- [CLAUDE.md](../CLAUDE.md) - Development guidance
- [dev_guide_ios.md](dev_guide_ios.md) - Integration guide
- [plan.md](plan.md) - Original improvement roadmap
- [accessibility-audit.md](accessibility-audit.md) - Historical audit (resolved)
- [memory-audit.md](memory-audit.md) - Historical audit (resolved)
