#include "CLPProvider.h"

@implementation CLPProvider
+ (HBPreferences *)sharedProvider {
    static dispatch_once_t once;
    static HBPreferences *sharedProvider;
    dispatch_once(&once, ^{
        sharedProvider = [[HBPreferences alloc] initWithIdentifier:@"com.thecasle.clearlockprefs"];
    });
    return sharedProvider;
}
@end
