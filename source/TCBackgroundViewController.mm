#import "headers.h"
#import "CLPProvider.h"

#import <substrate.h>
#import <notify.h>
#import "TCBackgroundViewController.h"
#import "_UIBackdropViewSettingsDynamic.h"

@import LocalAuthentication;

static BOOL alwaysLockBlurEnabled;
static BOOL isClearLockscreen;
static BOOL isClear;
static BOOL enableBlurLock;
static BOOL enableBlurHistory;

static double lockBlur;
static double lockSaturation;
static double lockColorAlpha;
static UIColor *lockColor = [UIColor blackColor];

//----------------------------------------------------------------

extern BOOL isOnLockscreen();
extern BOOL isUILocked();

void registerPreferences(){
    alwaysLockBlurEnabled = [prefs boolForKey:@"kAlwaysLockBlur"];
    isClearLockscreen = [prefs boolForKey:@"kClearLockscreen"];
    isClear = [prefs boolForKey:@"kTransparency"];
    enableBlurLock = [prefs boolForKey:@"kEnableBlurLock"];
    enableBlurHistory = [prefs boolForKey:@"kEnableBlurHistory"];
    
    lockBlur = [prefs doubleForKey:@"kLockBlur"];
    lockSaturation = [prefs doubleForKey:@"kLockSaturation"];
    lockColorAlpha = [prefs doubleForKey:@"kLockColorAlpha"];
}

int regToken;
uint32_t status = notify_register_dispatch("com.thecasle.clearlockprefs/ReloadPrefs", &regToken, dispatch_get_main_queue(), ^(int token) {
    registerPreferences();
});

@implementation TCBackgroundViewController {

}

- (instancetype) init{
    if(self = [super init]){
        registerPreferences();
        
        CGRect screenFrame = UIScreen.mainScreen.bounds;
        
        if(!self.view){
            self.view = [[UIView alloc] initWithFrame:screenFrame];
        }
        
        // NC blur
        if(!self.blurHistoryEffectView){
            // The BSUIBackdropView has so much customization its a little insane. Sort of unusual way to implement however.
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] initWithBlur: lockBlur
                                                                                                           saturation: (lockSaturation * 0.1)
                                                                                                                color: lockColor
                                                                                                           colorAlpha: lockColorAlpha];
            self.blurHistoryEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            
            self.blurHistoryEffectView.frame = screenFrame;
            self.blurHistoryEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurHistoryEffectView];
            if(!enableBlurHistory) self.blurHistoryEffectView.hidden = YES;
        }
        
        // lockscreen blur
        if(!self.blurEffectView){
            self.blurEffectView.frame = screenFrame;
            self.blurEffectView.alpha = 0;
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] initWithBlur: lockBlur
                                                                                                           saturation: (lockSaturation * 0.1)
                                                                                                                color: lockColor
                                                                                                           colorAlpha: lockColorAlpha];
            self.blurEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            self.blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurEffectView];
            if(!enableBlurLock) self.blurEffectView.hidden = YES;
        }
        
        if(!self.snapshotImageView){
            self.snapshotImageView = [[UIImageView alloc] initWithFrame:UIScreen.mainScreen.bounds];
            [self.view addSubview: self.snapshotImageView];
            [self.view sendSubviewToBack:self.snapshotImageView];
        }
        LAContext *context = [LAContext new];
        NSError *error;
        BOOL passcodeEnabled = [context canEvaluatePolicy:LAPolicyDeviceOwnerAuthentication error:&error];
        [[NSNotificationCenter defaultCenter] addObserverForName: @"SBBacklightFadeFinishedNotification" object:NULL queue:NULL usingBlock:^(NSNotification *note) {
            if (passcodeEnabled && isClearLockscreen && isClear) { // Only have to snapshot apps if there's authentication enabled
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
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName: @"SBFDeviceBlockStateDidChangeNotification" object:NULL queue:NULL usingBlock:^(NSNotification *note) {
            if (passcodeEnabled && isClearLockscreen && isClear) { // Only have to snapshot apps if there's authentication enabled
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
            }
        }];
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

-(void) updateWithContent: (BOOL)content isHistoryRevealed: (BOOL)isHistoryRevealed {
    
    // forces the blur always enabled
    if(alwaysLockBlurEnabled){
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
