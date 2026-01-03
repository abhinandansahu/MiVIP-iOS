# React Native MiVIP

[![npm version](https://img.shields.io/npm/v/@mitek/react-native-mivip.svg)](https://www.npmjs.com/package/@mitek/react-native-mivip)
[![npm version](https://img.shields.io/npm/v/@mitek/react-native-mivip.svg)](https://www.npmjs.com/package/@mitek/react-native-mivip)

React Native bridge for **MiVIP SDK** (Mitek Verified Identity Platform). This library allows you to integrate Mitek's identity verification flow (using MiSnap document capture and liveness detection) directly into your React Native iOS application.

## Features

- 📸 **QR Code Scanning**: Built-in scanner to capture verification request IDs.
- 🆔 **Manual Entry**: Start verification flows with a known request UUID.
- 🛡️ **Type-Safe**: Full TypeScript support with structured error types.
- 🔒 **Secure**: Thread-safe request handling and memory management.
- 📱 **Native UX**: Uses native iOS view controllers for optimal performance.

## Requirements

- iOS 13.0+
- React Native 0.64+
- Xcode 15.0+
- MiSnap SDK 5.9.1 (included via dependencies)

## Installation

### 1. Install the package

```bash
npm install @mitek/react-native-mivip
# or
yarn add @mitek/react-native-mivip
```

### 2. Install iOS dependencies

```bash
cd ios
pod install
```

### 3. Configure Permissions (Info.plist)

Add the following keys to your `Info.plist` file to allow camera access:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan QR codes and capture identity documents.</string>
```

### 4. Configure License Key

You must provide a valid MiSnap license key. This can be done in two ways:

**Option A: Info.plist (Recommended)**
Add your license key to `Info.plist`:

```xml
<key>MISNAP_LICENSE_KEY</key>
<string>YOUR_LICENSE_KEY_HERE</string>
```

**Option B: Programmatic Override**
Pass the license key when initializing the native module (advanced usage).

## Usage

### Scanning a QR Code

Opens the built-in camera scanner to read a MiVIP request ID from a QR code.

```typescript
import { scanQRCode, isMiVIPError, MiVIPErrorCode } from '@mitek/react-native-mivip';
import { Alert, Linking } from 'react-native';

async function handleScan() {
  try {
    const result = await scanQRCode();
    console.log('Verification Success:', result);
    Alert.alert('Success', 'Verification completed successfully!');
  } catch (error) {
    if (isMiVIPError(error)) {
      switch (error.code) {
        case MiVIPErrorCode.CAMERA_PERMISSION:
          Alert.alert(
            'Camera Access Required',
            error.userMessage,
            [{ text: 'Open Settings', onPress: () => Linking.openSettings() }]
          );
          break;
        case MiVIPErrorCode.INVALID_QR:
          Alert.alert('Invalid QR', 'Please scan a valid MiVIP verification code.');
          break;
        default:
          Alert.alert('Error', error.userMessage);
      }
    } else {
      Alert.alert('Error', 'An unexpected error occurred');
    }
  }
}
```

### Starting a Request Manually

If you already have the request ID (UUID), you can start the flow directly.

```typescript
import { startRequest } from '@mitek/react-native-mivip';

async function handleManualEntry(requestId: string) {
  try {
    // Validates UUID format automatically (trims whitespace, ignores case)
    const result = await startRequest(requestId);
    console.log('Verification Success:', result);
  } catch (error) {
    console.error('Verification failed:', error);
  }
}
```

## Error Handling

The library provides a structured `MiVIPError` type and `isMiVIPError` type guard.

### Error Codes (`MiVIPErrorCode`)

| Code | Description | Recoverable? |
|------|-------------|--------------|
| `E_INIT_FAILED` | SDK initialization failed (check license key) | ❌ |
| `E_CAMERA_PERMISSION` | User denied camera access | ❌ |
| `E_INVALID_QR` | Scanned code is not a valid request ID | ✅ |
| `E_INVALID_UUID` | Manual ID input is not a valid UUID | ✅ |
| `E_TIMEOUT` | Request timed out (60s limit) | ✅ |
| `E_REQUEST_IN_PROGRESS` | Another request is already active | ✅ |
| `E_SDK_ERROR` | Generic error from MiVIP SDK | ✅ |
| `E_VC_FAILED` | Failed to present view controller | ✅ |

### Error Object Structure

```typescript
interface MiVIPError {
  code: MiVIPErrorCode;
  message: string;      // Technical message
  userMessage: string;  // User-friendly message
  recoverable: boolean; // Can the user retry immediately?
}
```

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

Proprietary - See LICENSE file for details
