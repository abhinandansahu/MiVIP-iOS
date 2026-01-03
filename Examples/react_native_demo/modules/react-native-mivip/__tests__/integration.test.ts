import { NativeModules, Platform } from 'react-native';
import { scanQRCode, startRequest, MiVIPErrorCode } from '../src';

// Mock React Native modules
jest.mock('react-native', () => ({
  NativeModules: {
    MiVIPModule: {
      scanQRCode: jest.fn(),
      startRequest: jest.fn(),
    },
  },
  Platform: {
    select: jest.fn((obj) => obj.default),
  },
}));

describe('MiVIP Module Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('scanQRCode', () => {
    it('should resolve on successful QR scan', async () => {
      const mockResult = 'verification_complete';
      (NativeModules.MiVIPModule.scanQRCode as jest.Mock).mockResolvedValue(mockResult);

      const result = await scanQRCode();
      expect(result).toBe(mockResult);
      expect(NativeModules.MiVIPModule.scanQRCode).toHaveBeenCalled();
    });

    it('should throw structured error on QR scan failure', async () => {
      (NativeModules.MiVIPModule.scanQRCode as jest.Mock).mockRejectedValue({
        code: 'E_INVALID_QR',
        message: 'Invalid QR',
      });

      await expect(scanQRCode()).rejects.toMatchObject({
        code: MiVIPErrorCode.INVALID_QR,
        recoverable: true,
      });
    });

    it('should handle camera permission errors', async () => {
      (NativeModules.MiVIPModule.scanQRCode as jest.Mock).mockRejectedValue({
        code: 'E_CAMERA_PERMISSION',
        message: 'Denied',
      });

      await expect(scanQRCode()).rejects.toMatchObject({
        code: MiVIPErrorCode.CAMERA_PERMISSION,
        recoverable: false,
      });
    });
  });

  describe('startRequest', () => {
    it('should normalize UUID before sending to native', async () => {
      const uuid = '  ABC123-DEF4-5678-9012-ABCDEF123456  ';
      const expected = 'abc123-def4-5678-9012-abcdef123456';
      
      (NativeModules.MiVIPModule.startRequest as jest.Mock).mockResolvedValue('success');

      await startRequest(uuid);

      expect(NativeModules.MiVIPModule.startRequest).toHaveBeenCalledWith(expected);
    });

    it('should handle mixed case UUIDs', async () => {
      const uuid = 'AbC123-dEf4-5678-9012-aBcDeF123456';
      const expected = 'abc123-def4-5678-9012-abcdef123456';
      
      (NativeModules.MiVIPModule.startRequest as jest.Mock).mockResolvedValue('success');

      await startRequest(uuid);

      expect(NativeModules.MiVIPModule.startRequest).toHaveBeenCalledWith(expected);
    });

    it('should throw timeout error', async () => {
      (NativeModules.MiVIPModule.startRequest as jest.Mock).mockRejectedValue({
        code: 'E_TIMEOUT',
        message: 'Request timed out',
      });

      await expect(startRequest('valid-uuid')).rejects.toMatchObject({
        code: MiVIPErrorCode.TIMEOUT,
        recoverable: true,
      });
    });
  });
});
