#import "headers.h"
#import "CLPProvider.h"

#import <substrate.h>
#import "TCBackgroundViewController.h"
#import "_UIBackdropViewSettingsDynamic.h"

@import LocalAuthentication;

static BOOL alwaysLockBlurEnabled;
static BOOL alwaysNCBlurEnabled;

static double historyBlur;
static double lockBlur;
static double historySaturation;
static double lockSaturation;
static double historyColorAlpha;
static double lockColorAlpha;
static UIColor *historyColor = [UIColor blackColor];
static UIColor *lockColor = [UIColor blackColor];

//----------------------------------------------------------------

extern BOOL isOnLockscreen();
extern BOOL isUILocked();

@implementation TCBackgroundViewController {

}

- (instancetype) init{
    if(self = [super init]){
        [self registerPreferences];
        
        CGRect screenFrame = UIScreen.mainScreen.bounds;
        
        if(!self.view){
            self.view = [[UIView alloc] initWithFrame:screenFrame];
        }
        
        // NC blur
        if(!self.blurHistoryEffectView){
            // The BSUIBackdropView has so much customization its a little insane. Sort of unusual way to implement however.
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] initWithBlur: historyBlur
                                                                                                           saturation: historySaturation
                                                                                                                color: historyColor
                                                                                                           colorAlpha: historyColorAlpha];
            self.blurHistoryEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            
            self.blurHistoryEffectView.frame = screenFrame;
            self.blurHistoryEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurHistoryEffectView];
        }
        
        // lockscreen blur
        if(!self.blurEffectView){
            self.blurEffectView.frame = screenFrame;
            self.blurEffectView.alpha = 0;
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] initWithBlur: lockBlur
                                                                                                           saturation: lockSaturation
                                                                                                                color: lockColor
                                                                                                           colorAlpha: lockColorAlpha];
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
                    [UIView animateWithDuration:.2
                                          delay:0
                                        options:UIViewAnimationOptionCurveEaseInOut
                                     animations:^{self.snapshotImageView.alpha = 0;}
                                     completion:nil];
                } else{
                    if([(SpringBoard*)[UIApplication sharedApplication] _accessibilityFrontMostApplication] && isUILocked()){
                        self.snapshotImageView.alpha = 1;
                    }
                }
            }];
        }
    }
    return self;
}

+ (instancetype)sharedInstance {
    static TCBackgroundViewController *sharedInstance = nil;
    static dispatch_once_t onceToken; // onceToken = 0
    dispatch_once(&onceToken, ^{
        sharedInstance = [[TCBackgroundViewController alloc] init];
    });
    
    return sharedInstance;
}

-(void) registerPreferences{
    [prefs registerBool: &alwaysLockBlurEnabled default: YES forKey:@"kAlwaysLockBlurEnabled"];
    [prefs registerBool: &alwaysNCBlurEnabled default: YES forKey:@"kAlwaysNCBlurEnabled"];
    
    [prefs registerDouble: &historyBlur default: 10 forKey:@"kHistoryBlur"];
    [prefs registerDouble: &lockBlur default: 10 forKey:@"kLockBlur"];
    [prefs registerDouble: &historySaturation default: 1.2 forKey:@"kHistorySaturation"];
    [prefs registerDouble: &lockSaturation default: 1.2 forKey:@"kLockSaturation"];
    [prefs registerDouble: &historyColorAlpha default: 0 forKey:@"kHistoryColorAlpha"];
    [prefs registerDouble: &lockColorAlpha default: 0 forKey:@"kLockColorAlpha"];
}

-(void) updateWithContent: (BOOL)content isHistoryRevealed: (BOOL)isHistoryRevealed {
    
    // forces the blur always enabled
    if((alwaysLockBlurEnabled && isOnLockscreen()) || (alwaysNCBlurEnabled && !isOnLockscreen())){
        content = YES;
    }
    if(isOnLockscreen()){
        isHistoryRevealed = NO;
    }

    if(content == YES && isHistoryRevealed == YES){
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
