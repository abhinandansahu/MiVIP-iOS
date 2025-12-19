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

`Examples/whitelabel_demo/whitelabel_demo/ViewController.swift` demonstrates:
- Initializing MiVIPHub (may throw LicenseError if MiSnap license invalid)
- Setting optional configurations (sounds, wallet, logging, fonts)
- Launching different SDK flows (QR, direct request, code-based, history, account)
- Implementing RequestStatusDelegate for callbacks

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

## ⚠️ Known Code Quality Issues

**Comprehensive audits have identified critical issues in the example applications. See detailed reports:**
- **[Accessibility Audit](Docs/accessibility-audit.md)** - App Store rejection risk: **HIGH**
- **[Memory Leak Audit](Docs/memory-audit.md)** - Production stability risk: **MEDIUM**

### Critical Issues in Example Apps

**🚨 CRITICAL - App Store Blockers:**
1. **Non-accessible UI controls** (`ViewController.swift:118-136`)
   - Custom UIView buttons with gesture recognizers are not accessible to VoiceOver
   - **Impact**: App Store rejection, legal compliance issues (ADA/Section 508)
   - **Fix**: Replace with UIButton or add full accessibility support

2. **Missing Dynamic Type support** (`ViewController.swift:130`)
   - Hard-coded font sizes don't scale with user's accessibility settings
   - **Impact**: App Store rejection (required since iOS 11)
   - **Fix**: Use `UIFont.preferredFont(forTextStyle:)` with `adjustsFontForContentSizeCategory = true`

**⚠️ HIGH - User Experience Issues:**
3. **Missing VoiceOver labels on text fields** (`ViewController.swift:138-167`)
   - Text fields lack `accessibilityLabel` and `accessibilityHint`
   - **Impact**: VoiceOver users cannot understand form fields
   - **Fix**: Add descriptive accessibility labels to all text fields

**⚠️ MEDIUM - Memory Management Issues:**
4. **Gesture recognizer retain cycles** (`ViewController.swift:122-125`)
   - UIGestureRecognizer holds strong reference to view controller
   - **Impact**: View controller may not deallocate (~25-50 KB leak per instance)
   - **Fix**: Add cleanup in `deinit` or migrate to UIButton

5. **Unknown SDK delegate retention** (`ViewController.swift:69, 76, 83`)
   - MiVIPHub delegate retention strategy unknown (framework is binary)
   - **Impact**: Potential retain cycle if SDK uses strong reference
   - **Fix**: Use weak delegate wrapper or verify with Memory Graph Debugger

### Recommended Actions

**Before App Store Submission:**
1. ✅ Fix CRITICAL accessibility issues (see `Docs/accessibility-audit.md`)
2. ✅ Fix HIGH accessibility issues (VoiceOver labels, Dynamic Type)
3. ✅ Test with VoiceOver enabled
4. ✅ Test with maximum text size in Settings → Accessibility

**Before Production Deployment:**
1. ✅ Fix memory leak issues (see `Docs/memory-audit.md`)
2. ✅ Test with Memory Graph Debugger
3. ✅ Run Instruments Leaks tool
4. ✅ Verify view controller deallocation

**Implementation Plan:**
- See `Docs/plan.md` for comprehensive improvement roadmap
- Phase 1 addresses all CRITICAL and HIGH issues
- Phase 2 addresses MEDIUM memory issues

## Common Integration Issues

1. **MiSnap license errors:** Ensure valid MiSnap license configured before initializing MiVIPHub
2. **Missing NFC entitlements:** If using document NFC, verify all entitlement arrays and capability are set
3. **Framework embedding:** All XCFrameworks must be "Embed & Sign" not "Do Not Embed"
4. **Info.plist URL:** `HOOYU_API_URL` must point to correct MiVIP backend instance
5. **Font loading:** Custom fonts must be declared in Info.plist UIAppFonts before calling setFont methods
6. **Accessibility in custom UI:** When creating custom UI that integrates with SDK, ensure full VoiceOver support (see accessibility audit)
7. **Memory management with delegates:** Use weak references or weak wrappers when implementing RequestStatusDelegate (see memory audit)

## Best Practices for Integration

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
- **Accessibility audit:** `Docs/accessibility-audit.md` (⚠️ Read before App Store submission)
- **Memory leak audit:** `Docs/memory-audit.md` (⚠️ Read before production)
- **Improvement plan:** `Docs/plan.md` (Complete roadmap to production-ready code)
- **Third-party licenses:** `Docs/3rd_party_licensing_info.md`
- **MiSnap integration:** https://github.com/Mitek-Systems/MiSnap-iOS
