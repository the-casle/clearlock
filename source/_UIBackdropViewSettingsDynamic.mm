#include "headers.h"

#import <substrate.h>
#import "_UIBackdropViewSettingsDynamic.h"

// For some reason these need to be static instead of iVars, I'll figure this out eventually
static double blurValue;
static double colorAlphaValue;
static double saturationValue;
static UIColor *notificationCenterColoring;

//----------------------------------------------------------------
@implementation _UIBackdropViewSettingsDynamic

- (instancetype) initWithBlur:(double)blurRadius saturation:(double)saturation color:(UIColor *)color colorAlpha:(double)colorAlpha{
    if(self = [super init]){
        blurValue = blurRadius;
        saturationValue = saturation;
        notificationCenterColoring = color;
        colorAlphaValue = colorAlpha;
        
        [self setDefaultValues];
    }
    return self;
}
-(void)setDefaultValues{
    self.appliesTintAndBlurSettings = YES;
    self.scale = (blurValue >= 5) ? .25 : 1;
    self.usesBackdropEffectView = YES;
    self.backdropVisible = YES;
    self.filterMaskAlpha = 1;
    self.legibleColor = [UIColor whiteColor];
    self.enabled = YES;
    self.usesContentView = YES;
    self.saturationDeltaFactor = saturationValue;
    
    self.blurRadius = blurValue;
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
    self.colorTintAlpha = colorAlphaValue;
}
@end
