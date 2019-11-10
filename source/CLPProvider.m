#include "CLPProvider.h"

@implementation CLPProvider
+ (HBPreferences *)sharedProvider {
    static dispatch_once_t once;
    static HBPreferences *sharedProvider;
    dispatch_once(&once, ^{
        sharedProvider = [[HBPreferences alloc] initWithIdentifier:@"com.thecasle.clearlockprefs"];
        [sharedProvider registerDefaults:@{
                                        @"kTransparency": @YES,
                                        @"kClearLockscreen": @YES,
                                        @"kAlwaysLockBlur": @YES,
                                        @"kFlyInDisabled": @YES,
                                        @"kLockBlur": @10,
                                        @"kLockSaturation": @12,
                                        @"kLockColorAlpha": @0,
                                        @"kFadeUnlock": @YES,
                                        @"kEnableBlurLock": @YES,
                                        @"kEnableBlurHistory": @YES
                                        }];
    });
    return sharedProvider;
}
@end
