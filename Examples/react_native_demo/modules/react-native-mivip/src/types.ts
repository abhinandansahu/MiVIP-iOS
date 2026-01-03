/**
 * MiVIP Error Codes
 *
 * Structured error codes for all possible failure scenarios in the MiVIP SDK bridge.
 */
export enum MiVIPErrorCode {
  // Initialization
  INIT_FAILED = 'E_INIT_FAILED',
  VC_FAILED = 'E_VC_FAILED',

  // Permissions
  CAMERA_PERMISSION = 'E_CAMERA_PERMISSION',

  // Validation
  INVALID_QR = 'E_INVALID_QR',
  INVALID_UUID = 'E_INVALID_UUID',

  // Runtime
  SDK_ERROR = 'E_SDK_ERROR',
  TIMEOUT = 'E_TIMEOUT',
  REQUEST_IN_PROGRESS = 'E_REQUEST_IN_PROGRESS',

  // Unknown
  UNKNOWN = 'E_UNKNOWN',
}

/**
 * MiVIP Error
 *
 * Enhanced error object with user-friendly messages and recovery information.
 */
export interface MiVIPError extends Error {
  /** Error code for programmatic handling */
  code: MiVIPErrorCode;

  /** Technical error message for debugging */
  message: string;

  /** User-friendly error message suitable for display */
  userMessage: string;

  /** Whether the error is recoverable (user can retry) */
  recoverable: boolean;

  /** Original native error object (for debugging) */
  nativeError?: any;
}

/**
 * MiVIP Result
 *
 * Success response from verification request.
 */
export interface MiVIPResult {
  /** The verification request ID */
  requestId: string;

  /** Verification status */
  status: string;

  /** Timestamp of completion */
  timestamp: number;
}
