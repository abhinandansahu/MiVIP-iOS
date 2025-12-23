# React Native Implementation Plan

## Goal
Build a React Native example app (`react_native_demo`) that replicates the functionality and design of the native `whitelabel_demo` iOS app.

## Target Architecture
- **JS Layer**: React Native (TypeScript), React Navigation, Functional Components.
- **Native Layer**: Swift-based Native Module bridging `MiVIPSdk` and `MiVIPApi`.
- **Custom Logic**: Native `AVFoundation` QR scanner with UUID extraction (bypassing SDK parsing issues).

## Phases

### Phase 1: Environment Setup
- [x] Initialize React Native project in `Examples/react_native_demo`
- [x] Install dependencies
- [x] Configure `Info.plist` with required permissions

### Phase 2: Native Module Bridge (iOS)
- [x] Create `MiVIPModule` (Swift & Obj-C Bridge)
- [x] Port `CustomQRScannerViewController`
- [x] Implement `startRequest(id)` method
- [x] Implement `scanQRCode()` method
- [x] Link local XCFrameworks via local Pod `react-native-mivip`

### Phase 3: React Native UI Implementation
- [x] Create `Theme.ts` with Mitek Red branding (#EE2C46)
- [x] Build `HomeScreen` with 2-card layout
- [x] Implement `OptionCard` and `PrimaryButton` components
- [x] Add UUID validation logic in Javascript

### Phase 4: Integration & Verification
- [x] Connect JS UI to Native Module methods
- [x] Handle SDK status/error callbacks via Bridge
- [x] Verify build succeeds on iOS Simulator
- [x] Final code cleanup and documentation
