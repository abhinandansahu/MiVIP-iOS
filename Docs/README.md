# Setup & Development Guide

Follow these steps to set up, build, and run the modernized MiVIP-iOS `whitelabel_demo`.

## Prerequisites
- **Xcode 16.0+**
- **CocoaPods 1.15+**
- **Ruby 3.2+**
- A valid Mitek License Key bound to `com.mitek.abhi.mivipdemoapp`.

## 1. Project Setup

### Clone the Repository
```bash
git clone https://github.com/abhinandansahu/MiVIP-iOS.git
cd MiVIP-iOS/Examples/whitelabel_demo
```

### Install Dependencies
We use CocoaPods to manage the Mitek binary frameworks due to Git LFS stability issues with SPM.
```bash
pod install
```

### Open the Project
**Important**: Always open the `.xcworkspace` file, NOT the `.xcodeproj`.
```bash
open whitelabel_demo.xcworkspace
```

## 2. Configuration

### Bundle Identifier
The project is configured for:
- **Bundle ID**: `com.mitek.abhi.mivipdemoapp`
*If you change this ID, you must obtain a new matching license key from Mitek.*

### License Key
1. Locate `Config.xcconfig` (or check Build Settings).
2. Ensure `MISNAP_LICENSE_KEY` contains your valid key.

## 3. Build & Run

### Clean Build (Highly Recommended)
Because Xcode caches Bundle IDs and Info.plist values very aggressively, always clean when changing configuration:
1. **Cmd + Shift + K** (Clean)
2. **Cmd + Alt + Shift + K** (Clean Build Folder)

### Clear Simulator Cache (If Bundle ID issues persist)
In the Simulator:
- **Device** -> **Erase All Content and Settings...**

### Run
1. Select the `whitelabel_demo` scheme.
2. Select an **iPhone 16** (or newer) Simulator.
3. **Cmd + R** to run.

## 4. Troubleshooting
- **"License Invalid"**: Verify that the "Active Bundle ID" shown in the Xcode console exactly matches the ID authorized by Mitek.
- **"Module not found"**: Ensure you have opened the `.xcworkspace` and ran `pod install` successfully.
- **Haptic Pattern Errors**: Ignore these in the Simulator; they are expected as simulators lack haptic hardware.
