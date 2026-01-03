# Changelog

All notable changes to this project will be documented in this file.

## [3.6.15] - 2025-12-24

### Added
- Initial standalone package release
- QR code scanning support with native `AVCaptureSession`
- Manual request ID entry support with UUID validation
- TypeScript type definitions and structured error handling
- Comprehensive README and setup guide
- Unit and integration tests

### Fixed
- **Memory Leak**: Fixed leak in QR scanner callback chain using weak references and proper cleanup
- **Race Condition**: Implemented thread-safe request tracking with `DispatchQueue` barrier
- **Camera Permissions**: Added graceful permission checking and Settings redirect
- **Lifecycle**: Camera session now pauses/resumes correctly on app background/foreground
- **Security**: Externalized license key configuration (removed hardcoded credentials)
- **Validation**: Added RFC 4122 compliance check for UUID inputs

### Changed
- Refactored `MiVIPModule` to support concurrent requests
- Replaced generic error strings with structured `MiVIPErrorCode` enum
- Updated build system to output typed definitions (`.d.ts`)

### Security
- Added `.npmignore` to exclude development files and secrets
- Removed all hardcoded API keys and license tokens from source

## [Unreleased]

### Planned
- Android support
- Offline mode support
- Custom theming options
- Analytics integration
