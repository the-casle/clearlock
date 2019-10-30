#include "headers.h"

#import <substrate.h>
#import "TCBackgroundViewController.h"
#import "_UIBackdropViewSettingsDynamic.h"

@import LocalAuthentication;

static BOOL alwaysLockBlurEnabled = YES; // SETTING
static BOOL alwaysNCBlurEnabled = YES; // SETTING


//----------------------------------------------------------------

extern BOOL isOnLockscreen();
extern BOOL isUILocked();

@implementation TCBackgroundViewController {

}

- (instancetype) init{
    if(self = [super init]){
        CGRect screenFrame = UIScreen.mainScreen.bounds;
        
        if(!self.view){
            self.view = [[UIView alloc] initWithFrame:screenFrame];
        }
        
        // NC blur
        if(!self.blurHistoryEffectView){
            // The BSUIBackdropView has so much customization its a little insane. Sort of unusual way to implement however.
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] init];
            self.blurHistoryEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            
            self.blurHistoryEffectView.frame = screenFrame;
            self.blurHistoryEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurHistoryEffectView];
        }
        
        // lockscreen blur
        if(!self.blurEffectView){
            self.blurEffectView.frame = screenFrame;
            self.blurEffectView.alpha = 0;
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] init];
            self.blurEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurEffectView];
        }
        
        if(!self.snapshotImageView){
            self.snapshotImageView = [[UIImageView alloc] initWithFrame:UIScreen.mainScreen.bounds];
            [self.view addSubview: self.snapshotImageView];
            [self.view sendSubviewToBack:self.snapshotImageView];
        }
        LAContext *context = [LAContext new];
        NSError *error;
        BOOL passcodeEnabled = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error];
        
        if (passcodeEnabled) { // Only have to snapshot apps if there's authentication enabled
            [[NSNotificationCenter defaultCenter] addObserverForName: @"SBBacklightFadeFinishedNotification" object:NULL queue:NULL usingBlock:^(NSNotification *note) {
                if([(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication]){
                    if(!isUILocked()){
                        SBMainSwitcherViewController *mainSwitcherCont = [objc_getClass("SBMainSwitcherViewController") sharedInstance];
                        CGRect rect = [mainSwitcherCont.view bounds];
                        CGSize viewSize = rect.size;
                        UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
                        [mainSwitcherCont.view drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
                        UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        
                        self.snapshotImageView.image = img;
                    }
                } else {
                    self.snapshotImageView.alpha = 0;
                }
            }];
            
            [[NSNotificationCenter defaultCenter] addObserverForName: @"SBFDeviceBlockStateDidChangeNotification" object:NULL queue:NULL usingBlock:^(NSNotification *note) {
                if(MSHookIvar<NSUInteger>([objc_getClass("SBLockStateAggregator") sharedInstance], "_lockState") == 1){ // The device just was unlocked (treated as notification center)
                    [UIView animateWithDuration:.8
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{self.snapshotImageView.alpha = 0;}
                                     completion:nil];
                } else{
                    if([(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication]){
                        self.snapshotImageView.alpha = 1;
                    }
                }
            }];
        }
        
    }
    return self;
}

// Did someone say sharedInstance?
+ (instancetype)sharedInstance {
    static TCBackgroundViewController *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TCBackgroundViewController alloc] init];
    });
    
    return sharedInstance;
}

-(void) updateSceenShot: (BOOL)content isRevealed: (BOOL)isHistoryRevealed {
    
    // forces the blur always enabled
    if((alwaysLockBlurEnabled && isOnLockscreen()) || (alwaysNCBlurEnabled && !isOnLockscreen())){
        content = YES;
    }
    if(isOnLockscreen()){
        isHistoryRevealed = NO;
    }

    if(content == YES && isHistoryRevealed == YES){
        // Notification Center
        /*[UIView animateWithDuration:.5
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{self.blurHistoryEffectView.alpha = 1;}
                         completion:nil];*/
        self.blurHistoryEffectView.alpha = 1;
        self.blurEffectView.alpha = 0;
    } else if(content == YES && isHistoryRevealed == NO){
        // lockscreen
        [UIView animateWithDuration:.7
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{self.blurEffectView.alpha = 1;}
                         completion:nil];
        [UIView animateWithDuration:.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{self.blurHistoryEffectView.alpha = 0;}
                         completion:nil];
    } else {
        [UIView animateWithDuration:.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{self.blurHistoryEffectView.alpha = 0;}
                         completion:nil];
        [UIView animateWithDuration:.4
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{self.blurEffectView.alpha = 0;}
                         completion:nil];
    }
}
@end
