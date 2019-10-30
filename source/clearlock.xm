#import <substrate.h>
#import <Foundation/Foundation.h>

#import "clearlock.h"
#import "lockscreenfunction.h"

static id _instanceController;
static id _container;

BOOL isClearLockscreen = YES; // SETTING
BOOL isClear = YES; // SETTING

%hook SBCoverSheetUnlockedEnvironmentHostingWindow
-(void)setHidden:(BOOL)arg1 {
    if (isOnLockscreen() && !isClearLockscreen) %orig;
    else %orig(NO);
}
%end

%hook SBCoverSheetSlidingViewController
- (long long)dismissalSlidingMode {
    SBWallpaperController *wallpaperCont = [%c(SBWallpaperController) sharedInstance];
    if(isUILocked()){
        [wallpaperCont setVariant:0];
        [[wallpaperCont _window] setWindowLevel:1035]; // What it normally is
    }
    if(!isOnLockscreen() || isClearLockscreen){
        [wallpaperCont setVariant:1];
        [[wallpaperCont _window] setWindowLevel:-5]; // Below icons
    }
    if(isOnLockscreen() && !isClearLockscreen){
        ((UIView*)[%c(SBCoverSheetPanelBackgroundContainerView) sharedInstance]).alpha = 1;
    } else if(!isOnLockscreen()){
        [UIView animateWithDuration:.2
                              delay:.3
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{((UIView*)[%c(SBCoverSheetPanelBackgroundContainerView) sharedInstance]).alpha = 0;}
                         completion:nil];
    }
    return %orig;
}
%end

%hook _SBWallpaperWindow
-(void) setWindowLevel:(CGFloat) level{
    if(!isOnLockscreen() || isClearLockscreen){
        %orig(-5);
    } else %orig;
}
%end

%hook SBCoverSheetPanelBackgroundContainerView
// removes the animation when opening cover sheet
-(id) init{
    if (_container == nil) _container = %orig;
        else %orig; // just in case it needs more than one instance
    return _container;
}
%new
// add a shared instance so we can use it later
+ (id) sharedInstance {
    if (!_container) return [[%c(SBCoverSheetUnlockedEnvironmentHostingViewController) alloc] init];
    return _container;
}
%end

%hook SBWallpaperController
-(void)setVariant:(long long) arg1 {
    if(!isOnLockscreen()) {
        %orig(1);
    } else {
        %orig;
    }
}
%end

// The controller for the window
%hook SBCoverSheetUnlockedEnvironmentHostingViewController
-(id) init{
    if (_instanceController == nil) _instanceController = self;
        else %orig; // just in case it needs more than one instance
    return _instanceController;
}

%new
// add a shared instance so we can use it later
+ (id) sharedInstance {
    if (!_instanceController) return [[%c(SBCoverSheetUnlockedEnvironmentHostingViewController) alloc] init];
    return _instanceController;
}
%end

%hook SBHomeScreenWindow
-(id)_initWithScreen:(id)arg1 layoutStrategy:(id)arg2 debugName:(id)arg3 rootViewController:(id)arg4 scene:(id)arg5 {
    %orig;
    [self _setSecure:YES];
    return self;
}
%end

%hook SBCoverSheetTransitionSettings //Sinfool back at it
-(void)setIconsFlyIn:(BOOL) arg1{
    %orig(NO);
}
%end

%ctor{
    if(isClear) %init;
}
