#include "headers.h"
#import "TCBackgroundViewController.h"
#import "lockscreenfunction.h"

static BOOL enableXBanners;
static BOOL enableHeaders;
static BOOL enableExtend;
static BOOL enableGrabber;
static BOOL enableIconRemove;
static BOOL enableBannerSection;
static BOOL enableClearBackground;
static BOOL enableSeparators;
static BOOL enableNotifications;
static BOOL enableHideClock;
static BOOL enableHideText;

// palette
static BOOL paletteEnabled;
// colorbanners2
static BOOL colorBannersEnabled;

//static UIView *xenWidgetController;

static id _instanceController;
static id _container;


%hook NCNotificationListSectionRevealHintView
// bigger "No Older Notifications" text
-(void)layoutSubviews {
    %orig;
    if(enableHideText) MSHookIvar<UILabel *>(self, "_revealHintTitle").hidden = YES;
}
%end


%hook SBFLockScreenDateView
// hide clock
-(void)layoutSubviews {
    %orig;
    if (!isOnLockscreen() && enableHideClock) ((UIView*)self).hidden = YES;
    else ((UIView*)self).hidden = NO;
}
%end

%hook SBDashBoardWallpaperEffectView
// removes the wallpaper view when opening camera
// checks if the blur is visible when applying the new animation
-(void)layoutSubviews {
    %orig;
    if (((SBDashBoardViewController *)((UIView *)self).superview/* some touch thingy */.superview/* SBDashBoardView */._viewDelegate/* SBDashBoardViewController */).backgroundCont/* TCBackgroundController */.blurEffectView.alpha != 0 || ((SBDashBoardViewController *)((UIView *)self).superview/* some touch thingy */.superview/* SBDashBoardView */._viewDelegate/* SBDashBoardViewController */).backgroundCont/* TCBackgroundController */.blurHistoryEffectView.alpha != 0) ((UIView*)self).hidden = YES;
    else ((UIView*)self).hidden = NO;
}
%end

%hook NCNotificationCombinedListViewController
-(BOOL)hasContent{
    BOOL content = %orig;
    // Sending values to the background controller
    [[TCBackgroundViewController sharedInstance] updateSceenShot: content isRevealed: ((!isOnLockscreen()) ? YES : self.isShowingNotificationsHistory)]; // NC is never set to lock
    return content;
}
%end

%hook SBDashBoardViewController
%property (nonatomic, retain) TCBackgroundViewController *backgroundCont;
-(void)loadView{
    %orig;
    self.backgroundCont = [TCBackgroundViewController sharedInstance];
    [((SBDashBoardView *)self.view).backgroundView addSubview: self.backgroundCont.view];
}
// Hiding the dumb views that darken after scrollin in
-(void) viewWillLayoutSubviews {
    %orig;
    MSHookIvar<UIView *>(((SBDashBoardView *)self.view).backgroundView, "_sourceOverView").hidden = YES;
    MSHookIvar<UIView *>(((SBDashBoardView *)self.view).backgroundView, "_lightenSourceOverView").hidden = YES;
    MSHookIvar<UIView *>(((SBDashBoardView *)self.view).backgroundView, "_darkenSourceOverView").hidden = YES;
}
%end

// loading up that palette
static void loadPrefs() {
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/ch.mdaus.palette.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath: @"/Library/MobileSubstrate/DynamicLibraries/Palette.dylib"]){
        paletteEnabled = [settings objectForKey:@"bannersEnabled"] ? [[settings objectForKey:@"bannersEnabled"] boolValue] : NO;
    }
    NSMutableDictionary *colorBannerSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/mobile/Library/Preferences/com.golddavid.colorbanners2.plist"];
    if([[NSFileManager defaultManager] fileExistsAtPath: @"/Library/MobileSubstrate/DynamicLibraries/ColorBanners2.dylib"]){
        colorBannersEnabled = [colorBannerSettings objectForKey:@"BannersEnabled"] ? [[colorBannerSettings objectForKey:@"BannersEnabled"] boolValue] : NO;
    }
}

%ctor {
    // Fix rejailbreak bug
    if (![NSBundle.mainBundle.bundleURL.lastPathComponent.pathExtension isEqualToString:@"app"]) {
        return;
    }
    
    enableXBanners = YES;
    enableHeaders = YES;
    enableExtend = YES;
    enableGrabber = YES;
    enableIconRemove = NO;
    enableBannerSection = YES;
    enableClearBackground = YES;
    enableSeparators = YES;
    enableNotifications = YES;
    enableHideClock = NO;
    enableHideText = YES;
    
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("ch.mdaus.palette"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.golddavid.colorbanners2"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    
    %init;
}

