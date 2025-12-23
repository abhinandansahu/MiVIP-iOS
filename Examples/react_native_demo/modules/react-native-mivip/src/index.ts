import { NativeModules, Platform } from 'react-native';
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
 * Starts identity verification flow with a known request ID
 *
 * @param id - The verification request UUID
 * @returns Promise resolving to verification result string
 * @throws {MiVIPError} On invalid ID, timeout, or SDK error
 *
 * @example
 * ```typescript
 * try {
 *   const result = await startRequest('12345678-1234-1234-1234-123456789012');
 *   console.log('Verification result:', result);
 * } catch (error) {
 *   if (isMiVIPError(error)) {
 *     Alert.alert('Error', error.userMessage);
 *   }
 * }
 * ```
 */
export function startRequest(id: string): Promise<string> {
  // Normalize input at JS layer
  const normalizedId = id.trim().toLowerCase();

  return MiVIPModule.startRequest(normalizedId).catch((error: any) => {
    throw createMiVIPError(error);
  });
}

/**
 * Opens QR code scanner, extracts request ID, and starts verification flow
 *
 * @returns Promise resolving to verification result string
 * @throws {MiVIPError} On camera permission denial, invalid QR, or SDK error
 *
 * @example
 * ```typescript
 * try {
 *   const result = await scanQRCode();
 *   console.log('Verification result:', result);
 * } catch (error) {
 *   if (isMiVIPError(error)) {
 *     if (error.code === MiVIPErrorCode.CAMERA_PERMISSION) {
 *       Alert.alert('Camera Required', error.userMessage, [
 *         { text: 'Settings', onPress: () => Linking.openSettings() }
 *       ]);
 *     } else {
 *       Alert.alert('Error', error.userMessage);
 *     }
 *   }
 * }
 * ```
 */
export function scanQRCode(): Promise<string> {
  return MiVIPModule.scanQRCode().catch((error: any) => {
    throw createMiVIPError(error);
  });
}

// Re-export types for consumer convenience
export * from './types';
export { createMiVIPError, isMiVIPError } from './errors';
