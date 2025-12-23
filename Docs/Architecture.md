# MiVIP-iOS Modernized Architecture

## Overview
The `whitelabel_demo` has been refactored from a Storyboard-based, tightly coupled application into a modern **MVVM-C (Model-View-ViewModel-Coordinator)** architecture. This ensures the app is testable, maintainable, and adheres to latest iOS development standards.

## Current Architecture Components
- **Coordinator (AppCoordinator & MiVIPCoordinator)**: Handles all navigation logic and view controller lifecycle.
- **Router (AppRouter)**: Abstracted navigation controller wrapper to allow for easy pushing/presenting.
- **ViewModel (MiVIPHubViewModel)**: Contains the business logic and state management, using **Combine** to bind to the UI.
- **Dependency Container**: Manages the initialization and lifecycle of services (DI).
- **Service Layer (MiVIPService)**: Wraps the Mitek SDK with modern Swift features like `async/await`.

## Key Learnings & Resolutions
### 1. Dependency Management (The LFS Problem)
We discovered that the Mitek MiSnap SPM repository uses **Git LFS** for binaries. Standard SPM checkouts in many environments fail to pull these large files, resulting in "Missing module" or "Empty XCFramework" errors.
- **Resolution**: Reverted to **CocoaPods** for the sample app. It remains the most reliable way to consume the Mitek SDK binaries until their SPM/LFS implementation is stabilized with zip-hosted binaries.

### 2. Binary Compatibility (Xcode 16)
Binary frameworks built with older Swift versions (e.g., 5.10) without `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` often cause module stability errors in Xcode 16.
- **Resolution**: Forced the project to `Swift 5.10` and ensured the linker and framework search paths are strictly managed by CocoaPods.

### 3. License & Bundle ID Binding
Mitek license keys are cryptographically bound to a specific Bundle ID. Changing the ID in Xcode without a matching key triggers a silent SDK initialization failure.
- **Resolution**: Implemented a **Fallback Service** (`MiVIPServiceFallback`) that catches initialization errors and provides user-friendly alerts instead of crashing the application.

---

## Gaps & Weaknesses
- **Storyboard Remnants**: While the app entry is now programmatic, some UI elements still rely on the SDK's internal storyboards.
- **State Persistence**: Currently, the request history is managed by the SDK; the app lacks a local database for offline request tracking.
- **Testing**: While structure supports it, the project requires deeper UI/Snapshot testing.

---

## 3-Phase Upgrade Path

### Phase 1: UI & Experience Modernization
- **Transition to SwiftUI**: Replace the UIKit `ViewController` with a SwiftUI implementation using the existing ViewModels.
- **Dynamic Theming**: Implement a robust theme manager supporting multi-brand "White Label" configurations beyond basic colors.

### Phase 2: Security Hardening
- **SSL Pinning**: Fully implement the provided `SSLPinningDelegate` for all network traffic.
- **Biometric Locking**: Add FaceID/TouchID protection for the "Account" and "History" sections.
- **Device Integrity**: Integrate App Attest/DeviceCheck to ensure the SDK is running on a non-compromised device.

### Phase 3: Modularization & CI/CD
- **Local Swift Packages**: Move the `Service` and `Coordinator` logic into a local Swift Package for reuse across multiple apps.
- **Automated License Rotation**: Build a CI script that fetches the latest license key from a secure vault (like AWS Secrets Manager) and injects it into `Config.xcconfig` during build time.
