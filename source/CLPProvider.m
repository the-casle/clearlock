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
                                        @"kAlwaysNCBlur": @YES,
                                        @"kFlyInDisabled": @YES,
                                        @"kHistoryBlur": @10,
                                        @"kLockBlur": @10,
                                        @"kHistorySaturation": @12,
                                        @"kLockSaturation": @12,
                                        @"kHistoryColorAlpha": @0,
                                        @"kLockColorAlpha": @0
                                        }];
    });
    return sharedProvider;
}
@end
