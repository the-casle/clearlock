#include "headers.h"
#import "TCBackgroundViewController.h"
#import "lockscreenfunction.h"

static BOOL enableHideText = YES; // SETTING

static id _instanceController;
static id _container;


%hook NCNotificationListSectionRevealHintView
// bigger "No Older Notifications" text
-(void)layoutSubviews {
    %orig;
    if(enableHideText) MSHookIvar<UILabel *>(self, "_revealHintTitle").hidden = YES;
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
    [[TCBackgroundViewController sharedInstance] updateWithContent: content isHistoryRevealed: ((!isOnLockscreen()) ? YES : self.isShowingNotificationsHistory)]; // NC is never set to lock
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

%ctor {
    // Fix rejailbreak bug
    if (![NSBundle.mainBundle.bundleURL.lastPathComponent.pathExtension isEqualToString:@"app"]) {
        return;
    }
    %init;
}

