# MiVIP React Native Demo

This is a React Native implementation of the MiVIP-iOS SDK integration, mirroring the functionality of the `whitelabel_demo`.

## Prerequisites
- Node.js (v18+)
- Xcode 15+
- CocoaPods
- Valid MiSnap License Key (configured in `Info.plist`)

## Setup Instructions

1. **Install JS Dependencies**
   ```bash
   cd Examples/react_native_demo
   npm install
   ```

2. **Install Native Dependencies**
   ```bash
   cd ios
   pod install
   ```

3. **Configure API URL**
   Ensure `HOOYU_API_URL` is set in your `Info.plist` (default is EU environment).

4. **Run the App**
   ```bash
   npm run ios
   ```

## Features
- **Native QR Scanning**: Uses a custom `AVFoundation` scanner for maximum reliability.
- **Mitek Branding**: Official Mitek Red (#EE2C46) theme.
- **Hybrid Modularity**: Clean separation between SDK logic and UI.
- **Validation**: Real-time UUID validation for manual entry.
