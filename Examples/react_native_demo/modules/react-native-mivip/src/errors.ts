import { MiVIPError, MiVIPErrorCode } from './types';

/**
 * User-friendly error messages mapped to error codes
 */
const ERROR_MESSAGES: Record<MiVIPErrorCode, string> = {
  [MiVIPErrorCode.INIT_FAILED]:
    'Unable to initialize identity verification. Please check your license key configuration.',
  [MiVIPErrorCode.VC_FAILED]:
    'Unable to display verification screen. Please try again.',
  [MiVIPErrorCode.CAMERA_PERMISSION]:
    'Camera access is required for QR code scanning. Please enable camera access in Settings.',
  [MiVIPErrorCode.INVALID_QR]:
    "The QR code is invalid or doesn't contain a verification request. Please scan the code from your verification email.",
  [MiVIPErrorCode.INVALID_UUID]:
    'Invalid verification request ID format. Please check the ID and try again.',
  [MiVIPErrorCode.SDK_ERROR]:
    'An error occurred during verification. Please try again.',
  [MiVIPErrorCode.TIMEOUT]:
    'The verification request timed out. Please check your network connection and try again.',
  [MiVIPErrorCode.REQUEST_IN_PROGRESS]:
    'A verification request is already in progress. Please wait for it to complete.',
  [MiVIPErrorCode.UNKNOWN]:
    'An unexpected error occurred. Please try again.',
};

/**
 * Error codes that allow user retry
 */
const RECOVERABLE_ERRORS = new Set<MiVIPErrorCode>([
  MiVIPErrorCode.INVALID_QR,
  MiVIPErrorCode.INVALID_UUID,
  MiVIPErrorCode.TIMEOUT,
  MiVIPErrorCode.SDK_ERROR,
  MiVIPErrorCode.REQUEST_IN_PROGRESS,
]);

/**
 * Creates a structured MiVIPError from a native error object
 *
 * @param nativeError - Error object from the native module
 * @returns Structured MiVIPError with user-friendly messages
 */
export function createMiVIPError(nativeError: any): MiVIPError {
  const code = (nativeError?.code as MiVIPErrorCode) || MiVIPErrorCode.UNKNOWN;
  const message = nativeError?.message || 'Unknown error';

  const error = new Error(message) as MiVIPError;
  error.code = code;
  error.message = message;
  error.userMessage =
    ERROR_MESSAGES[code] || ERROR_MESSAGES[MiVIPErrorCode.UNKNOWN];
  error.recoverable = RECOVERABLE_ERRORS.has(code);
  error.nativeError = nativeError;

  return error;
}

/**
 * Type guard to check if an error is a MiVIPError
 *
 * @param error - Error object to check
 * @returns True if error is a MiVIPError
 */
export function isMiVIPError(error: unknown): error is MiVIPError {
  return (
    error instanceof Error &&
    'code' in error &&
    'userMessage' in error &&
    'recoverable' in error
  );
}
