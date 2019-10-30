#import <Cephei/HBPreferences.h>
#define prefs [CLPProvider sharedProvider]

@interface CLPProvider : NSObject
+(HBPreferences *)sharedProvider;
@end
