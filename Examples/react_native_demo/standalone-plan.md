# React Native MiVIP - Standalone Package Extraction Plan

**Objective:** Extract `react-native-mivip` from the demo app into a standalone, publishable npm package for reuse across multiple React Native projects.

**Target Version:** 3.6.15 (aligned with MiVIP SDK version)

---

## Current State

**Location:** `Examples/react_native_demo/modules/react-native-mivip/`

**Structure:**
```
modules/react-native-mivip/
├── ios/
│   ├── MiVIPModule.m           # Objective-C bridge registration
│   ├── MiVIPModule.swift       # Swift implementation
│   └── CustomQRScannerViewController.swift
├── src/
│   └── index.ts                # TypeScript interface
├── package.json                # Basic metadata
└── react-native-mivip.podspec  # CocoaPods spec
```

**Issues:**
- Embedded in demo app (not reusable)
- No build process (TypeScript not compiled)
- Minimal documentation
- No versioning strategy
- Critical bugs identified in code review (see Issues #1-10)

---

## Phase 1: Pre-Extraction Preparation

### 1.1 Fix Critical Bugs (Before Extraction)

These issues must be resolved before creating standalone package to avoid distributing known bugs:

**Priority 1 - Security:**
- ✅ **Issue #5:** Move hardcoded license key to Config.xcconfig
  - Create `Config.xcconfig.example` as template
  - Add to `.gitignore`
  - Update documentation

**Priority 2 - Memory & Stability:**
- **Issue #1:** Memory leak in QR scanner callback
  - Add timeout handling (60s)
  - Implement request tracking dictionary
  - Ensure cleanup in all code paths

- **Issue #2:** Missing camera permission checks
  - Add `AVCaptureDevice.authorizationStatus` check
  - Implement permission request flow
  - Show alert with Settings redirect on denial

- **Issue #3:** Camera session lifecycle
  - Add `viewWillDisappear` to stop session
  - Add `viewDidAppear` to restart session
  - Test backgrounding scenarios

- **Issue #4:** Race condition in concurrent bridge calls
  - Replace instance properties with dictionary
  - Add serial queue for thread safety
  - Handle multiple in-flight requests

**Priority 3 - Developer Experience:**
- **Issue #6:** Structured error types in TypeScript
  - Create `src/types.ts` with error enums
  - Add user-friendly error messages
  - Implement error transformation layer

- **Issue #10:** Input validation improvements
  - Add UUID normalization (trim, lowercase)
  - Update regex validation
  - Test copy-paste scenarios

### 1.2 Enhance Package Metadata

**Update `package.json`:**
```json
{
  "name": "@mitek/react-native-mivip",
  "version": "3.6.15",
  "description": "React Native bridge for MiVIP SDK - Identity verification with document capture and liveness detection",
  "main": "lib/index.js",
  "types": "lib/index.d.ts",
  "files": ["lib/", "ios/", "react-native-mivip.podspec"],
  "scripts": {
    "build": "tsc",
    "prepare": "npm run build",
    "test": "jest",
    "lint": "eslint src/ --ext .ts,.tsx"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/Mitek-Systems/react-native-mivip.git"
  },
  "keywords": [
    "react-native",
    "ios",
    "mivip",
    "identity-verification",
    "kyc",
    "biometric",
    "document-capture",
    "liveness"
  ],
  "author": "Mitek Systems Inc.",
  "license": "SEE LICENSE IN LICENSE",
  "peerDependencies": {
    "react": ">=16.8.0",
    "react-native": ">=0.64.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "@types/react-native": "^0.71.0",
    "typescript": "^5.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "@testing-library/react-native": "^12.0.0"
  },
  "engines": {
    "node": ">=14.0.0"
  }
}
```

### 1.3 Add TypeScript Build Configuration

**Create `tsconfig.json`:**
```json
{
  "compilerOptions": {
    "target": "ES2017",
    "module": "commonjs",
    "lib": ["ES2017"],
    "declaration": true,
    "declarationMap": true,
    "outDir": "./lib",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "jsx": "react-native"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "lib", "**/*.test.ts"]
}
```

### 1.4 Create Comprehensive Documentation

**README.md Sections:**
1. **Installation**
   - npm/yarn commands
   - iOS setup (CocoaPods, Info.plist)
   - Android setup (future)
   - License key configuration

2. **Quick Start**
   - QR code scanning example
   - Manual request ID example
   - Error handling patterns

3. **API Reference**
   - `scanQRCode()` documentation
   - `startRequest(id)` documentation
   - Error types and codes
   - TypeScript types

4. **Configuration**
   - Required Info.plist keys
   - Permission descriptions
   - Backend URL setup
   - License key setup (using Config.xcconfig)

5. **Architecture**
   - How the bridge works
   - Native module structure
   - Delegate pattern explanation

6. **Troubleshooting**
   - Common errors and solutions
   - Camera permission issues
   - License validation failures
   - Network connectivity problems

7. **Requirements**
   - iOS version (13.0+)
   - React Native version (0.64+)
   - MiSnap SDK dependency
   - License requirements

**Create CHANGELOG.md:**
```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [3.6.15] - 2025-12-24

### Added
- Initial standalone package release
- QR code scanning support
- Manual request ID entry support
- TypeScript type definitions
- Comprehensive error handling

### Fixed
- Memory leak in QR scanner callback chain
- Missing camera permission pre-checks
- Camera session lifecycle management
- Race condition in concurrent bridge calls
- Hardcoded license key security issue
- UUID validation edge cases

### Security
- Externalized license key to Config.xcconfig
- Added .gitignore for sensitive configuration

## [Unreleased]

### Planned
- Android support
- Offline mode support
- Custom theming options
- Analytics integration
```

**Create LICENSE file:**
```
Proprietary License

Copyright (c) 2025 Mitek Systems Inc.

This software and associated documentation files (the "Software") are the
proprietary and confidential information of Mitek Systems Inc.

The Software is licensed, not sold. This license grants you limited rights
to use the Software solely for integration with Mitek's MiVIP SDK.

Redistribution and use in source and binary forms are prohibited without
prior written permission from Mitek Systems Inc.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND.
```

---

## Phase 2: Repository Setup

### 2.1 Create New Repository

**Option A: Separate Repository (Recommended)**
```bash
# Create new repo
mkdir react-native-mivip
cd react-native-mivip
git init
git remote add origin https://github.com/Mitek-Systems/react-native-mivip.git
```

**Option B: Monorepo Subdirectory**
```
MiVIP-iOS/
├── SDKs/                    # Existing
├── Examples/
│   ├── whitelabel_demo/     # Existing
│   └── react_native_demo/   # Existing
└── Packages/
    └── react-native-mivip/  # New standalone location
```

### 2.2 Directory Structure

```
react-native-mivip/
├── .github/
│   └── workflows/
│       ├── test.yml         # CI for tests
│       └── publish.yml      # Automated npm publishing
├── ios/
│   ├── MiVIPModule.h
│   ├── MiVIPModule.m
│   ├── MiVIPModule.swift
│   └── CustomQRScannerViewController.swift
├── src/
│   ├── index.ts             # Main export
│   ├── types.ts             # TypeScript types
│   └── errors.ts            # Error handling
├── lib/                     # Compiled output (gitignored)
│   ├── index.js
│   ├── index.d.ts
│   └── ...
├── __tests__/
│   ├── MiVIPModule.test.ts
│   └── errors.test.ts
├── .gitignore
├── .npmignore
├── .eslintrc.js
├── package.json
├── tsconfig.json
├── jest.config.js
├── react-native-mivip.podspec
├── README.md
├── CHANGELOG.md
├── LICENSE
└── Config.xcconfig.example  # Template for license key
```

### 2.3 Configure .gitignore

```gitignore
# Build outputs
lib/
node_modules/
*.tgz

# IDE
.vscode/
.idea/
*.swp
*.swo

# Sensitive configuration
Config.xcconfig
*.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# OS
.DS_Store
Thumbs.db
```

### 2.4 Configure .npmignore

```npmignore
# Source files (publish compiled only)
src/
__tests__/
*.test.ts

# Development files
.github/
.eslintrc.js
tsconfig.json
jest.config.js

# Documentation (except README)
*.md
!README.md

# Build artifacts
*.log

# Examples
examples/
```

---

## Phase 3: Code Improvements

### 3.1 Refactor Native Module (iOS)

**MiVIPModule.swift Improvements:**

```swift
import Foundation
import MiVIPSdk
import MiVIPApi

@objc(MiVIPModule)
class MiVIPModule: NSObject, RCTBridgeModule, RequestStatusDelegate {

    static func moduleName() -> String! { return "MiVIPModule" }
    static func requiresMainQueueSetup() -> Bool { return true }

    // MARK: - Properties

    private var mivipHub: MiVIPHub?
    private var initError: String?

    // Track multiple in-flight requests
    private var pendingRequests: [String: PendingRequest] = [:]
    private let requestQueue = DispatchQueue(label: "com.mitek.mivip.requests")

    // Request timeout timer
    private var requestTimers: [String: Timer] = [:]
    private let timeoutInterval: TimeInterval = 60

    // MARK: - Initialization

    override init() {
        super.init()
        do {
            self.mivipHub = try MiVIPHub()
            print("MiVIPModule: Initialized successfully")
        } catch {
            self.initError = "Failed to initialize MiVIPHub: \(error.localizedDescription)"
            print("MiVIPModule: \(self.initError!)")
        }
    }

    // MARK: - Bridge Methods

    @objc
    func scanQRCode(_ resolver: @escaping RCTPromiseResolveBlock,
                    rejecter: @escaping RCTPromiseRejectBlock) {
        guard mivipHub != nil else {
            rejecter("E_INIT_FAILED", initError ?? "SDK not initialized", nil)
            return
        }

        // Check camera permission first
        checkCameraPermission { [weak self] granted in
            if granted {
                self?.presentQRScanner(resolver: resolver, rejecter: rejecter)
            } else {
                rejecter("E_CAMERA_PERMISSION",
                        "Camera access is required. Please enable it in Settings.",
                        nil)
            }
        }
    }

    @objc
    func startRequest(_ id: String,
                     resolver: @escaping RCTPromiseResolveBlock,
                     rejecter: @escaping RCTPromiseRejectBlock) {
        guard let hub = mivipHub else {
            rejecter("E_INIT_FAILED", initError ?? "SDK not initialized", nil)
            return
        }

        // Validate UUID format
        guard UUID(uuidString: id) != nil else {
            rejecter("E_INVALID_UUID", "Invalid request ID format", nil)
            return
        }

        requestQueue.async { [weak self] in
            guard let self = self else { return }

            // Check for duplicate request
            if self.pendingRequests[id] != nil {
                DispatchQueue.main.async {
                    rejecter("E_REQUEST_IN_PROGRESS",
                            "Request \(id) is already in progress",
                            nil)
                }
                return
            }

            // Store request callbacks
            self.pendingRequests[id] = PendingRequest(
                resolve: resolver,
                reject: rejecter
            )

            // Start timeout timer
            DispatchQueue.main.async {
                self.startTimeoutTimer(for: id)

                guard let topVC = self.getTopViewController() else {
                    self.rejectRequest(id: id,
                                     code: "E_VC_FAILED",
                                     message: "Could not find valid screen to present SDK")
                    return
                }

                hub.request(vc: topVC,
                          miVipRequestId: id,
                          requestStatusDelegate: self)
            }
        }
    }

    // MARK: - RequestStatusDelegate

    func status(status: MiVIPApi.RequestStatus?,
                result: MiVIPApi.RequestResult?,
                scoreResponse: MiVIPApi.ScoreResponse?,
                request: MiVIPApi.MiVIPRequest?) {
        guard let request = request, let requestId = request.id else {
            print("MiVIPModule: Received status without request ID")
            return
        }

        if let result = result {
            resolveRequest(id: requestId, result: String(describing: result))
        }
    }

    func error(err: String) {
        print("MiVIPModule: SDK Error - \(err)")

        // Reject all pending requests (SDK doesn't provide request context)
        requestQueue.async { [weak self] in
            guard let self = self else { return }

            let pendingIds = Array(self.pendingRequests.keys)
            for id in pendingIds {
                self.rejectRequest(id: id, code: "E_SDK_ERROR", message: err)
            }
        }
    }

    // MARK: - Private Helpers

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: completion)
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func presentQRScanner(resolver: @escaping RCTPromiseResolveBlock,
                                  rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [weak self] in
            guard let topVC = self?.getTopViewController() else {
                rejecter("E_VC_FAILED", "Could not find valid screen", nil)
                return
            }

            let scanner = CustomQRScannerViewController()
            scanner.onCodeScanned = { [weak self, weak scanner] code in
                scanner?.dismiss(animated: true) { [weak self] in
                    if let uuid = self?.extractUUID(from: code) {
                        self?.startRequest(uuid, resolver: resolver, rejecter: rejecter)
                    } else {
                        rejecter("E_INVALID_QR", "QR code does not contain valid request ID", nil)
                    }
                }
            }

            topVC.present(scanner, animated: true)
        }
    }

    private func extractUUID(from string: String) -> String? {
        // Try direct parsing first
        if let uuid = UUID(uuidString: string) {
            return uuid.uuidString.lowercased()
        }

        // Extract from URL or longer string
        let pattern = "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }

        let range = NSRange(string.startIndex..., in: string)
        if let match = regex.firstMatch(in: string, range: range),
           let r = Range(match.range, in: string) {
            let candidate = String(string[r])
            // Validate it's a proper UUID
            if UUID(uuidString: candidate) != nil {
                return candidate.lowercased()
            }
        }

        return nil
    }

    private func startTimeoutTimer(for requestId: String) {
        requestTimers[requestId]?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: timeoutInterval, repeats: false) { [weak self] _ in
            self?.rejectRequest(id: requestId,
                              code: "E_TIMEOUT",
                              message: "Request timed out after \(Int(self?.timeoutInterval ?? 60)) seconds")
        }

        requestTimers[requestId] = timer
    }

    private func resolveRequest(id: String, result: String) {
        requestQueue.async { [weak self] in
            guard let self = self,
                  let request = self.pendingRequests[id] else { return }

            DispatchQueue.main.async {
                self.requestTimers[id]?.invalidate()
                self.requestTimers.removeValue(forKey: id)
                request.resolve(result)
            }

            self.pendingRequests.removeValue(forKey: id)
        }
    }

    private func rejectRequest(id: String, code: String, message: String) {
        requestQueue.async { [weak self] in
            guard let self = self,
                  let request = self.pendingRequests[id] else { return }

            DispatchQueue.main.async {
                self.requestTimers[id]?.invalidate()
                self.requestTimers.removeValue(forKey: id)
                request.reject(code, message, nil)
            }

            self.pendingRequests.removeValue(forKey: id)
        }
    }

    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootVC = window.rootViewController else {
            return nil
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
}

// MARK: - Supporting Types

private struct PendingRequest {
    let resolve: RCTPromiseResolveBlock
    let reject: RCTPromiseRejectBlock
}
```

**CustomQRScannerViewController.swift Improvements:**

```swift
import UIKit
import AVFoundation

class CustomQRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var onCodeScanned: ((String) -> Void)?

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        checkPermissionAndSetup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopSession()
    }

    // MARK: - Camera Permission

    private func checkPermissionAndSetup() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupScanner()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupScanner()
                    } else {
                        self?.showPermissionDeniedAlert()
                    }
                }
            }
        case .denied, .restricted:
            showPermissionDeniedAlert()
        @unknown default:
            showPermissionDeniedAlert()
        }
    }

    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(
            title: "Camera Access Required",
            message: "Please enable camera access in Settings to scan QR codes.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in
            self?.dismiss(animated: true)
        })

        present(alert, animated: true)
    }

    // MARK: - Scanner Setup

    private func setupScanner() {
        let session = AVCaptureSession()

        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            showError("Unable to access camera")
            return
        }

        session.addInput(input)

        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else {
            showError("Unable to configure camera output")
            return
        }

        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.layer.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)

        self.captureSession = session
        self.previewLayer = preview

        setupCancelButton()
    }

    private func setupCancelButton() {
        let cancel = UIButton(type: .system)
        cancel.setTitle("Cancel", for: .normal)
        cancel.tintColor = .label
        cancel.backgroundColor = UIColor.systemGray.withAlphaComponent(0.3)
        cancel.layer.cornerRadius = 8
        cancel.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cancel.titleLabel?.adjustsFontForContentSizeCategory = true

        // Accessibility
        cancel.accessibilityLabel = "Cancel QR Code Scanning"
        cancel.accessibilityHint = "Returns to the previous screen without scanning"
        cancel.accessibilityTraits = .button

        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        cancel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(cancel)
        NSLayoutConstraint.activate([
            cancel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            cancel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            cancel.widthAnchor.constraint(equalToConstant: 80),
            cancel.heightAnchor.constraint(equalToConstant: 44)
        ])

        // View accessibility
        view.accessibilityLabel = "QR Code Scanner"
        view.accessibilityHint = "Position a QR code within the camera view to scan"
    }

    // MARK: - Session Management

    private func startSession() {
        guard let session = captureSession, !session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    private func stopSession() {
        guard let session = captureSession, session.isRunning else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            session.stopRunning()
        }
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate

    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else { return }

        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        stopSession()
        onCodeScanned?(stringValue)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
}
```

### 3.2 Enhance TypeScript Layer

**src/types.ts:**

```typescript
export enum MiVIPErrorCode {
  INIT_FAILED = 'E_INIT_FAILED',
  VC_FAILED = 'E_VC_FAILED',
  SDK_ERROR = 'E_SDK_ERROR',
  INVALID_QR = 'E_INVALID_QR',
  INVALID_UUID = 'E_INVALID_UUID',
  TIMEOUT = 'E_TIMEOUT',
  CAMERA_PERMISSION = 'E_CAMERA_PERMISSION',
  REQUEST_IN_PROGRESS = 'E_REQUEST_IN_PROGRESS',
}

export interface MiVIPError {
  code: MiVIPErrorCode;
  message: string;
  userMessage: string;
  recoverable: boolean;
}

export interface MiVIPResult {
  requestId: string;
  status: string;
  timestamp: number;
}
```

**src/errors.ts:**

```typescript
import { MiVIPError, MiVIPErrorCode } from './types';

const ERROR_MESSAGES: Record<string, string> = {
  [MiVIPErrorCode.INIT_FAILED]:
    'Unable to initialize verification. Please check your license key.',
  [MiVIPErrorCode.INVALID_QR]:
    'Invalid QR code. Please scan the code from your verification email.',
  [MiVIPErrorCode.INVALID_UUID]:
    'Invalid request ID format. Please check and try again.',
  [MiVIPErrorCode.CAMERA_PERMISSION]:
    'Camera access is required. Please enable it in Settings.',
  [MiVIPErrorCode.TIMEOUT]:
    'Request timed out. Please check your connection and try again.',
  [MiVIPErrorCode.REQUEST_IN_PROGRESS]:
    'A verification is already in progress.',
  [MiVIPErrorCode.SDK_ERROR]:
    'An error occurred. Please try again.',
  [MiVIPErrorCode.VC_FAILED]:
    'Unable to display verification screen.',
};

const RECOVERABLE_ERRORS = new Set([
  MiVIPErrorCode.INVALID_QR,
  MiVIPErrorCode.INVALID_UUID,
  MiVIPErrorCode.TIMEOUT,
  MiVIPErrorCode.SDK_ERROR,
]);

export function createMiVIPError(nativeError: any): MiVIPError {
  const code = (nativeError.code as MiVIPErrorCode) || MiVIPErrorCode.SDK_ERROR;

  return {
    code,
    message: nativeError.message || 'Unknown error',
    userMessage: ERROR_MESSAGES[code] || ERROR_MESSAGES[MiVIPErrorCode.SDK_ERROR],
    recoverable: RECOVERABLE_ERRORS.has(code),
  };
}
```

**src/index.ts:**

```typescript
import { NativeModules, Platform } from 'react-native';
import { MiVIPError } from './types';
import { createMiVIPError } from './errors';

const LINKING_ERROR =
  `The package 'react-native-mivip' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const MiVIPModule = NativeModules.MiVIPModule
  ? NativeModules.MiVIPModule
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );

/**
 * Opens QR scanner, extracts request ID, and starts verification flow
 * @returns Promise resolving to verification result
 * @throws {MiVIPError} On camera permission denial, invalid QR, or SDK error
 */
export function scanQRCode(): Promise<string> {
  return MiVIPModule.scanQRCode().catch((error: any) => {
    throw createMiVIPError(error);
  });
}

/**
 * Starts verification flow with a known request ID
 * @param id - The verification request UUID
 * @returns Promise resolving to verification result
 * @throws {MiVIPError} On invalid ID format, timeout, or SDK error
 */
export function startRequest(id: string): Promise<string> {
  // Normalize input
  const normalizedId = id.trim().toLowerCase();

  return MiVIPModule.startRequest(normalizedId).catch((error: any) => {
    throw createMiVIPError(error);
  });
}

// Re-export types
export * from './types';
export { createMiVIPError } from './errors';
```

---

## Phase 4: Testing Strategy

### 4.1 Unit Tests

**`__tests__/errors.test.ts`:**

```typescript
import { createMiVIPError, MiVIPErrorCode } from '../src';

describe('MiVIP Error Handling', () => {
  it('should create structured error from native error', () => {
    const nativeError = {
      code: 'E_INVALID_QR',
      message: 'QR code does not contain valid request ID',
    };

    const error = createMiVIPError(nativeError);

    expect(error.code).toBe(MiVIPErrorCode.INVALID_QR);
    expect(error.userMessage).toContain('scan the code from your verification email');
    expect(error.recoverable).toBe(true);
  });

  it('should mark camera permission errors as non-recoverable', () => {
    const nativeError = {
      code: 'E_CAMERA_PERMISSION',
      message: 'Camera access denied',
    };

    const error = createMiVIPError(nativeError);
    expect(error.recoverable).toBe(false);
  });
});
```

**`__tests__/integration.test.ts`:**

```typescript
import { NativeModules } from 'react-native';
import { scanQRCode, startRequest, MiVIPErrorCode } from '../src';

jest.mock('react-native', () => ({
  NativeModules: {
    MiVIPModule: {
      scanQRCode: jest.fn(),
      startRequest: jest.fn(),
    },
  },
  Platform: { select: jest.fn() },
}));

describe('MiVIP Module Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should resolve on successful QR scan', async () => {
    const mockResult = 'verification_complete';
    NativeModules.MiVIPModule.scanQRCode.mockResolvedValue(mockResult);

    const result = await scanQRCode();
    expect(result).toBe(mockResult);
  });

  it('should throw structured error on QR scan failure', async () => {
    NativeModules.MiVIPModule.scanQRCode.mockRejectedValue({
      code: 'E_INVALID_QR',
      message: 'Invalid QR',
    });

    await expect(scanQRCode()).rejects.toMatchObject({
      code: MiVIPErrorCode.INVALID_QR,
      recoverable: true,
    });
  });

  it('should normalize UUID before sending to native', async () => {
    const uuid = '  ABC123-DEF4-5678-9012-ABCDEF123456  ';
    NativeModules.MiVIPModule.startRequest.mockResolvedValue('success');

    await startRequest(uuid);

    expect(NativeModules.MiVIPModule.startRequest).toHaveBeenCalledWith(
      'abc123-def4-5678-9012-abcdef123456'
    );
  });
});
```

### 4.2 Integration Testing

**Manual Test Checklist:**
- [ ] QR scanner opens and camera preview visible
- [ ] Camera permission alert shows on first use
- [ ] Settings redirect works from permission alert
- [ ] Cancel button dismisses scanner
- [ ] Valid QR code triggers verification flow
- [ ] Invalid QR code shows error message
- [ ] Manual UUID entry accepts valid IDs
- [ ] Manual UUID entry rejects invalid formats
- [ ] Whitespace/casing normalized in UUID input
- [ ] Concurrent requests handled correctly
- [ ] Request timeout triggers after 60s
- [ ] Memory leak fixed (use Instruments)
- [ ] Dark mode styling correct
- [ ] VoiceOver navigation works
- [ ] Dynamic Type text scales properly

---

## Phase 5: Distribution

### 5.1 Publishing Options

**Option A: Private npm Registry (Recommended)**

```bash
# Setup
npm config set registry https://npm.mitek.com
npm config set //npm.mitek.com/:_authToken=${NPM_TOKEN}

# Publish
npm publish --access restricted
```

**Option B: GitHub Packages**

```json
// package.json
{
  "name": "@mitek/react-native-mivip",
  "publishConfig": {
    "registry": "https://npm.pkg.github.com"
  }
}
```

```bash
# Setup .npmrc in consuming projects
@mitek:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}

# Publish
npm publish
```

**Option C: Git Dependency (No npm)**

```json
// Consumer package.json
{
  "dependencies": {
    "@mitek/react-native-mivip": "git+ssh://git@github.com/Mitek-Systems/react-native-mivip.git#v3.6.15"
  }
}
```

### 5.2 CI/CD Pipeline

**`.github/workflows/test.yml`:**

```yaml
name: Test

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npx tsc --noEmit

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage/coverage-final.json
```

**`.github/workflows/publish.yml`:**

```yaml
name: Publish

on:
  release:
    types: [created]

jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          registry-url: 'https://npm.pkg.github.com'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build

      - name: Test
        run: npm test

      - name: Publish to GitHub Packages
        run: npm publish
        env:
          NODE_AUTH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Phase 6: Migration Guide for Demo App

Once standalone package is published, update `react_native_demo`:

### 6.1 Update package.json

```diff
{
  "dependencies": {
-   "react-native-mivip": "file:./modules/react-native-mivip",
+   "@mitek/react-native-mivip": "^3.6.15",
    "react": "18.2.0",
    "react-native": "0.73.0"
  }
}
```

### 6.2 Remove Local Module

```bash
cd Examples/react_native_demo
rm -rf modules/react-native-mivip
npm install
cd ios && pod install
```

### 6.3 Update Imports (No Change Needed)

```typescript
// Imports stay the same
import { scanQRCode, startRequest } from '@mitek/react-native-mivip';
```

### 6.4 Update Error Handling

```typescript
import { scanQRCode, MiVIPErrorCode } from '@mitek/react-native-mivip';

try {
  const result = await scanQRCode();
  Alert.alert('Success', `Result: ${result}`);
} catch (error: any) {
  if (error.code === MiVIPErrorCode.CAMERA_PERMISSION) {
    Alert.alert(
      'Camera Required',
      error.userMessage,
      [{ text: 'Open Settings', onPress: () => Linking.openSettings() }]
    );
  } else {
    Alert.alert('Error', error.userMessage);
  }
}
```

---

## Success Criteria

✅ **Quality:**
- All 10 code review issues fixed
- 80%+ test coverage
- No memory leaks (validated with Instruments)
- VoiceOver accessible
- Dark mode support

✅ **Documentation:**
- Comprehensive README
- API reference with examples
- Troubleshooting guide
- Migration guide from embedded version

✅ **Distribution:**
- Published to npm/GitHub Packages
- Semantic versioning implemented
- Automated CI/CD pipeline

✅ **Usability:**
- Installation takes <5 minutes
- Demo app successfully uses published package
- Partners can integrate without contacting Mitek support

---

## Timeline Estimate

| Phase | Tasks | Estimated Effort |
|-------|-------|-----------------|
| Phase 1 | Fix bugs, enhance metadata, add docs | 2-3 days |
| Phase 2 | Repository setup, directory structure | 0.5 day |
| Phase 3 | Code refactoring (native + TypeScript) | 2-3 days |
| Phase 4 | Write tests, manual testing | 1-2 days |
| Phase 5 | Publishing setup, CI/CD | 1 day |
| Phase 6 | Migrate demo app | 0.5 day |
| **Total** | | **7-10 days** |

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|----------|
| Breaking changes to SDK API | High | Version lock to MiVIP 3.6.x, document compatibility |
| License key distribution | High | Use Config.xcconfig pattern, document in README |
| Android support missing | Medium | Mark as iOS-only initially, add Android in v3.7.0 |
| Native SDK updates | Medium | Maintain compatibility matrix in README |

---

## Future Enhancements (v3.7.0+)

- [ ] Android support
- [ ] Offline mode support
- [ ] Custom theming API
- [ ] Analytics integration
- [ ] WebView bridge for hybrid apps
- [ ] Swift Package Manager distribution
- [ ] Example project in standalone repo
- [ ] Storybook for component documentation

---

## References

- [React Native Native Modules (iOS)](https://reactnative.dev/docs/native-modules-ios)
- [CocoaPods Podspec Syntax](https://guides.cocoapods.org/syntax/podspec.html)
- [npm Publishing Guide](https://docs.npmjs.com/cli/v9/commands/npm-publish)
- [Semantic Versioning](https://semver.org/)
- [MiVIP SDK Documentation](../../../Docs/dev_guide_ios.md)
- [Code Review Report](./code-review-results.md)
