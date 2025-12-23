#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MiVIPModule, NSObject)

RCT_EXTERN_METHOD(startRequest:(NSString *)id
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(scanQRCode:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

@end
