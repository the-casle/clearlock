#include "headers.h"

#import <substrate.h>
#import "_UIBackdropViewSettingsDynamic.h"

static NSNumber *blurValueHistory;
static NSNumber *darkeningValueHistory;
static NSNumber *saturationValueHistory;
static UIColor *notificationCenterColoring;

static NSString *notifHex;

//----------------------------------------------------------------
@implementation _UIBackdropViewSettingsDynamic

- (instancetype) init{
    if(self = [super init]){
        /*HBPreferences *settings = [[HBPreferences alloc] initWithIdentifier:@"com.thecasle.nineprefs"];
        [settings registerDefaults:@{
                                     @"historyBlurValue": @20,
                                     @"historyDarkeningValue":@4,
                                     @"historySaturationValue":@12,
                                     }];
        
        [settings registerObject:&notifHex default:@"#000000" forKey: @"notificationCenterColors"];
        notificationCenterColoring = LCPParseColorString(notifHex, @"#000000");
        */
        blurValueHistory = @20;
        //[NSNumber numberWithDouble: [settings doubleForKey:@"historyBlurValue"]];
        darkeningValueHistory = @.4;
        //[NSNumber numberWithDouble: ([settings doubleForKey:@"historyDarkeningValue"] * .1)];
        saturationValueHistory = @1.2;
        //[NSNumber numberWithDouble: ([settings doubleForKey:@"historySaturationValue"] * .1)];
        
        [self setDefaultValues];
        //self = [objc_getClass("_UIBackdropViewSettingsNone") settingsForPrivateStyle:1];
    }
    return self;
}
-(void)setDefaultValues{
    
    self.appliesTintAndBlurSettings = YES;
    self.scale = (saturationValueHistory.doubleValue >= 5) ? .25 : 1;
    self.usesBackdropEffectView = YES;
    self.backdropVisible = YES;
    self.filterMaskAlpha = 1;
    self.legibleColor = [UIColor whiteColor];
    self.enabled = YES;
    self.usesContentView = YES;
    self.saturationDeltaFactor = saturationValueHistory.doubleValue;
    
    self.blurRadius = blurValueHistory.doubleValue;
    self.blurQuality = @"default";
    
    self.darkeningTintBrightness = .64;
    self.darkeningTintHue = .619;
    self.darkeningTintSaturation = .2;
    self.darkeningTintAlpha = .2;
    self.usesDarkeningTintView = YES;
    
    self.grayscaleTintMaskAlpha = 1;
    
    self.usesColorTintView = YES;
    self.colorTint = notificationCenterColoring;
    self.colorTintMaskAlpha = 1;
    self.colorTintAlpha = darkeningValueHistory.doubleValue;
}
@end
