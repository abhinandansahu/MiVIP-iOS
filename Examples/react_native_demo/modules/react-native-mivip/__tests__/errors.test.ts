import { createMiVIPError, MiVIPErrorCode } from '../src';

describe('MiVIP Error Handling', () => {
  it('should create structured error from native error', () => {
    const nativeError = {
      code: 'E_INVALID_QR',
      message: 'QR code does not contain valid request ID',
    };

    const error = createMiVIPError(nativeError);

    expect(error.code).toBe(MiVIPErrorCode.INVALID_QR);
    expect(error.message).toBe('QR code does not contain valid request ID');
    expect(error.userMessage).toContain('scan the code from your verification email');
    expect(error.recoverable).toBe(true);
  });

  it('should mark camera permission errors as non-recoverable', () => {
    const nativeError = {
      code: 'E_CAMERA_PERMISSION',
      message: 'Camera access denied',
    };

    const error = createMiVIPError(nativeError);
    expect(error.code).toBe(MiVIPErrorCode.CAMERA_PERMISSION);
    expect(error.recoverable).toBe(false);
  });

  it('should handle unknown errors gracefully', () => {
    const nativeError = {
      code: 'E_UNKNOWN_ERROR',
      message: 'Something weird happened',
    };

    const error = createMiVIPError(nativeError);
    expect(error.code).toBe(MiVIPErrorCode.UNKNOWN);
    expect(error.message).toBe('Something weird happened');
    expect(error.recoverable).toBe(false);
  });

  it('should handle errors without code', () => {
    const nativeError = {
      message: 'Just a message',
    };

    const error = createMiVIPError(nativeError);
    expect(error.code).toBe(MiVIPErrorCode.UNKNOWN);
    expect(error.message).toBe('Just a message');
  });

  it('should provide user-friendly messages for all error codes', () => {
    const errorCodes = Object.values(MiVIPErrorCode);
    
    errorCodes.forEach((code) => {
      const nativeError = { code, message: 'Test' };
      const error = createMiVIPError(nativeError);
      
      expect(error.userMessage).toBeDefined();
      expect(error.userMessage.length).toBeGreaterThan(0);
    });
  });
});
