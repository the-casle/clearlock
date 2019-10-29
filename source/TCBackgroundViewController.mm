#include "headers.h"

#import <substrate.h>
#import "TCBackgroundViewController.h"
#import "_UIBackdropViewSettingsDynamic.h"

static BOOL alwaysBlurEnabled;

//----------------------------------------------------------------

extern BOOL isOnLockscreen();
extern BOOL isUILocked();

@implementation TCBackgroundViewController {

}

- (instancetype) init{
    if(self = [super init]){
        CGRect frame = UIScreen.mainScreen.bounds;
        frame.size.width = (frame.size.width > frame.size.height) ? frame.size.width : frame.size.height;
        frame.size.height = (frame.size.width > frame.size.height) ? frame.size.width : frame.size.height;

        CGRect screenFrame = UIScreen.mainScreen.bounds;

        alwaysBlurEnabled = YES; // SETTING
        
        if(!self.view){
            self.view = [[UIView alloc] initWithFrame:screenFrame];
        }
        
        // NC blur
        if(!self.blurHistoryEffectView){
            // The BSUIBackdropView has so much customization its a little insane. Sort of unusual way to implement however.
            _UIBackdropViewSettings *settings = [[objc_getClass("_UIBackdropViewSettingsDynamic") alloc] init];
            
            self.blurHistoryEffectView = [[objc_getClass("BSUIBackdropView") alloc] initWithSettings:settings];
            
            self.blurHistoryEffectView.frame = frame;
            self.blurHistoryEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.view addSubview:self.blurHistoryEffectView];
        }
        
        // lockscreen blur
        if(!self.blurEffectView){
            self.blurEffectView.frame = frame;
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
        
        [[NSNotificationCenter defaultCenter] addObserverForName: @"SBBacklightFadeFinishedNotification" object:NULL queue:NULL usingBlock:^(NSNotification *note) {
            
            

            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            NSLog(@"nine_TWEAK | %@", keyWindow);
            CGRect rect = [keyWindow bounds];
            
            CGSize viewSize = rect.size;
            UIGraphicsBeginImageContextWithOptions(viewSize, NO, 0.0);
            [keyWindow drawViewHierarchyInRect:CGRectMake(0, 0, viewSize.width, viewSize.height) afterScreenUpdates:YES];
            UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();

            self.snapshotImageView.image = img;
        }];
        
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
    if(alwaysBlurEnabled || !isOnLockscreen()){
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
