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
        blurValueHistory = @10;
        darkeningValueHistory = @.4;
        saturationValueHistory = @1.2;
        [self setDefaultValues];
    }
    return self;
}
-(void)setDefaultValues{
    self.appliesTintAndBlurSettings = YES;
    self.scale = (blurValueHistory.doubleValue >= 5) ? .25 : 1;
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
