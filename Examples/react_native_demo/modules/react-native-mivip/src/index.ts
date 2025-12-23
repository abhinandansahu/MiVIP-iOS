import { NativeModules, Platform } from 'react-native';

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

export function startRequest(id: string): Promise<string> {
  return MiVIPModule.startRequest(id);
}

export function scanQRCode(): Promise<string> {
  return MiVIPModule.scanQRCode();
}
