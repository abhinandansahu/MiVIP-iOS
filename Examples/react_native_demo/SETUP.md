# React Native MiVIP Demo - Setup Instructions

## Prerequisites

- Node.js 14+
- Xcode 15.0+
- CocoaPods
- MiSnap license key (contact Mitek Systems)

## Initial Setup

### 1. Install Dependencies

```bash
# Install JavaScript dependencies
npm install

# Install iOS dependencies
cd ios
pod install
cd ..
```

### 2. Configure License Key (Basic Solution)

The MiVIP SDK requires a valid license key to function. 

**Option A: Hardcode in Info.plist (Easiest)**

1. Open `ios/react_native_demo/Info.plist`
2. Locate the `MISNAP_LICENSE_KEY` key
3. Replace `REPLACE_WITH_YOUR_LICENSE_KEY` with your actual base64 license key

**Option B: Set Programmatically (Recommended for Security)**

If you want to keep the license key out of version control:

1. Create a `MiVIPLicense.swift` file (add to `.gitignore`)
2. In `MiVIPModule.swift`, call the license manager before initializing `MiVIPHub`:

```swift
import MiSnapCore

// Inside init()
MiSnapLicenseManager.shared.setLicenseKey("YOUR_ACTUAL_KEY")
```

## Running the App

### iOS

```bash
# Start Metro bundler
npm start

# In another terminal, run iOS app
npm run ios
```

### Troubleshooting

#### License Key Errors

If you see "SDK not initialized" errors:

1. Verify the license key in `Info.plist` is correct
2. Ensure there are no leading/trailing whitespaces in the key
3. Check that the license key is valid and not expired

#### Camera Not Working

Ensure Info.plist contains:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to capture identity documents.</string>
```

#### Network Errors

1. Check that `HOOYU_API_URL` points to the correct backend
2. Verify network connectivity
3. Check iOS simulator/device network settings

## Security Best Practices

### ✅ DO:
- Keep `Config.xcconfig` in `.gitignore`
- Use environment-specific configuration files
- Rotate license keys periodically
- Limit access to license keys

### ❌ DON'T:
- Commit `Config.xcconfig` to version control
- Share license keys in chat/email
- Hardcode license keys in source code
- Include license keys in screenshots/documentation

## File Structure

```
react_native_demo/
├── ios/
│   └── react_native_demo/
│       └── Info.plist                 # Contains license key placeholder
├── SETUP.md                           # This file
```

## Team Onboarding

When a new developer joins:

1. Provide them with a license key securely (1Password, encrypted email)
2. Have them add it to their local `Info.plist` or a gitignored file
3. Verify their setup runs successfully

## CI/CD Integration

For automated builds (GitHub Actions, Fastlane):

1. Store license key in CI secrets
2. Create `Config.xcconfig` during build:

```bash
# Example GitHub Actions
echo "MISNAP_LICENSE_KEY = ${{ secrets.MISNAP_LICENSE_KEY }}" > ios/react_native_demo/Config.xcconfig
echo "HOOYU_API_URL = ${{ secrets.HOOYU_API_URL }}" >> ios/react_native_demo/Config.xcconfig
```

## Additional Resources

- [MiVIP SDK Documentation](../../Docs/dev_guide_ios.md)
- [MiSnap Integration Guide](https://github.com/Mitek-Systems/MiSnap-iOS)
- [React Native Setup](https://reactnative.dev/docs/environment-setup)

## Support

For license key issues or questions, contact:
- Mitek Support: support@miteksystems.com
- Account Manager: (provided separately)
