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

### 2. Configure License Key (Critical - Security)

**⚠️ IMPORTANT:** The license key must be configured in a gitignored file to prevent accidental exposure.

```bash
# Navigate to iOS project directory
cd ios/react_native_demo

# Copy the example configuration
cp Config.xcconfig.example Config.xcconfig

# Edit Config.xcconfig and add your license key
# Replace YOUR_LICENSE_KEY_HERE with your actual MiSnap license key
```

**Config.xcconfig structure:**

```xcconfig
// MiSnap SDK License Key
MISNAP_LICENSE_KEY = eyJ... (your actual license key)

// MiVIP Backend URL
HOOYU_API_URL = https:/$()/eu-west.id.miteksystems.com
```

**Environment-specific URLs:**
- Development: `https://dev.id.miteksystems.com`
- Staging: `https://staging.id.miteksystems.com`
- Production (EU): `https://eu-west.id.miteksystems.com`
- Production (US): `https://us.id.miteksystems.com`

### 3. Link Configuration in Xcode

The `Config.xcconfig` file must be linked to your Xcode project:

1. Open `react_native_demo.xcworkspace` in Xcode
2. Select the project in the navigator (blue icon)
3. Select the "react_native_demo" project (not target)
4. Go to the "Info" tab
5. Under "Configurations", set:
   - Debug: `Config`
   - Release: `Config`

If "Config" doesn't appear:
1. Click the dropdown
2. Select "Other..."
3. Navigate to `ios/react_native_demo/Config.xcconfig`

### 4. Verify Setup

After configuration, the Info.plist should contain:

```xml
<key>MISNAP_LICENSE_KEY</key>
<string>$(MISNAP_LICENSE_KEY)</string>

<key>HOOYU_API_URL</key>
<string>$(HOOYU_API_URL)</string>
```

These variables will be replaced at build time with values from `Config.xcconfig`.

## Running the App

### iOS

```bash
# Start Metro bundler
npm start

# In another terminal, run iOS app
npm run ios

# Or open in Xcode and run
open ios/react_native_demo.xcworkspace
```

### Troubleshooting

#### License Key Errors

If you see "SDK not initialized" errors:

1. Verify `Config.xcconfig` exists and contains your license key
2. Clean build folder: Xcode → Product → Clean Build Folder (Cmd+Shift+K)
3. Rebuild the project
4. Check that the license key is valid and not expired

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
│       ├── Config.xcconfig.example    # Template (committed)
│       ├── Config.xcconfig            # Your config (gitignored)
│       └── Info.plist                 # Uses $(VARIABLES)
├── .gitignore                         # Excludes Config.xcconfig
└── SETUP.md                           # This file
```

## Team Onboarding

When a new developer joins:

1. Share the template: `Config.xcconfig.example`
2. Provide them with a license key securely (1Password, encrypted email)
3. Have them create their own `Config.xcconfig`
4. Verify their setup runs successfully

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
