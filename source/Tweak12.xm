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

// Hiding the dumb action buttons when in nc
%hook SBDashBoardQuickActionsViewController
-(void) _updateState {
    %orig;
    if(!isOnLockscreen()) ((UIView *)self.view).hidden = YES;
    else ((UIView *)self.view).hidden = NO;
}
%end


%hook NCNotificationListCollectionView
-(UIEdgeInsets) adjustedContentInset {
    UIEdgeInsets inset = %orig;
    if(enableHideClock){
        if(!isOnLockscreen()  && [(SpringBoard*)[UIApplication sharedApplication] nowPlayingProcessPID] == 0){
            if(@available(iOS 11.0, *)) inset.top = self.safeAreaInsets.top;
            return inset;
        } else if(!isOnLockscreen()  && [(SpringBoard*)[UIApplication sharedApplication] nowPlayingProcessPID] > 0){
            if(@available(iOS 11.0, *)) inset.top -= (205 - self.safeAreaInsets.top);
            return inset;
        } else return %orig;
    } else return %orig;
    
}
-(CGPoint) minimumContentOffset {
    if(enableHideClock){
        CGPoint point = %orig;
        if(!isOnLockscreen()  && [(SpringBoard*)[UIApplication sharedApplication] nowPlayingProcessPID] == 0){
            if(@available(iOS 11.0, *)) point.y = self.safeAreaInsets.top;
        } else if(!isOnLockscreen()  && [(SpringBoard*)[UIApplication sharedApplication] nowPlayingProcessPID] > 0){
            if(@available(iOS 11.0, *))point.y -= (205 - self.safeAreaInsets.top);
        }
        return point;
    } else return %orig;
}

%end
/*
// For xen
%hook XENHWidgetLayerContainerView
-(id) init {
    if((self = %orig)){
        if(!xenWidgetController) xenWidgetController = ((UIView *)self);
    }
    return nil;
}
%end
*/
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
-(void) _updatePrioritySectionLowestPosition{
    %orig;
    [self hasContent]; // Updating the background.
    if(enableSeparators){
        for(NCNotificationListCell *cell in self.collectionView.visibleCells){
            if([cell isKindOfClass:%c(NCNotificationListCell)]){
                NCNotificationShortLookView *shortView = ((NCNotificationShortLookView *)((NCNotificationViewControllerView *)cell.contentViewController.view).contentView);
                if([shortView isKindOfClass:%c(NCNotificationShortLookView)] && [shortView respondsToSelector:@selector(tcUpdateTopLine)]){
                    [shortView tcUpdateTopLine];
                }
            }
        }
    }
}
%end

%hook SBDashBoardViewController
%property (nonatomic, retain) TCBackgroundViewController *backgroundCont;
-(id)initWithPageViewControllers:(id)arg1 mainPageContentViewController:(id)arg2{
    if((self = %orig)){
        self.backgroundCont = [TCBackgroundViewController sharedInstance];
    }
    return self;
}
-(void)loadView{
    %orig;
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

%group ShortLookGeneral
%hook NCNotificationShortLookView
%property (nonatomic, assign, getter=isNineBanner) BOOL nineBanner;
%property (nonatomic, retain) _UITableViewCellSeparatorView *singleLine;
%property (nonatomic, retain) _UITableViewCellSeparatorView *topLine;
%property (nonatomic, retain) UIVisualEffectView *notifEffectView;
%property (nonatomic, retain) UIView *extendedView;
-(void) layoutSubviews{
    %orig;
    
    if([[self _viewControllerForAncestor] respondsToSelector:@selector(delegate)]){
        self.nineBanner = [[[self _viewControllerForAncestor] delegate] isKindOfClass:%c(SBNotificationBannerDestination)];
    }
    
    NCNotificationGrabberView *grabberView = MSHookIvar<NCNotificationGrabberView *>(self, "_grabberView"); // Grabber used for later;
    if(self.isNineBanner)[self handleBanner];
    else [self handleNotification];
    
    %orig;
    
    if(!self.isNineBanner && !enableNotifications) grabberView.hidden = YES;
}
-(BOOL)_shouldShowGrabber {
    return enableBannerSection ? YES : %orig;
}

%new
-(void) handleBanner{
    NCNotificationGrabberView *grabberView = MSHookIvar<NCNotificationGrabberView *>(self, "_grabberView");
    if(enableBannerSection){
        MSHookIvar<UIImageView *>(self, "_shadowView").hidden = YES;
        if(colorBannersEnabled){
            for(id object in ((UIView *)[self backgroundMaterialView]).allSubviews){
                if ([object respondsToSelector:@selector(_cornerRadius)]) [((UIView *) object) _setCornerRadius:0];
            }
        } else {
            //Sets all text to white color
            UIColor *white = [UIColor whiteColor];
            
            [[self _headerContentView] setTintColor:white];
            [[[[self _headerContentView] _dateLabel] _layer] setFilters:nil];
            [[[[self _headerContentView] _titleLabel] _layer] setFilters:nil];
            
            [[self.notificationContentView _secondaryTextView] setTextColor:white];
            [[self.notificationContentView _primaryLabel] setTextColor:white];
            [[self.notificationContentView _primarySubtitleLabel] setTextColor:white];
            if ([self.notificationContentView respondsToSelector:@selector(_secondaryLabel)]) [[self.notificationContentView _secondaryLabel] setTextColor:white];
            
            [[self backgroundMaterialView] setHidden:YES];
        }
// MAKE SURE TO FIX IPX BANNERS FOR NOTIFCA!!!!!!!!!!!!!!!!!!!!!
        MSHookIvar<MTMaterialView *>(self, "_mainOverlayView").hidden = true;
        
        CGPoint notifCenter = self.center;
        notifCenter.x = self.superview.center.x;
        self.center = notifCenter;
        
        if(!self.notifEffectView){
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithBlurRadius:17];
            self.notifEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            
            // Palette banners
            if(paletteEnabled && self.backgroundView){
                self.notifEffectView.backgroundColor = [UIColor clearColor];
                self.backgroundView.frame = self.bounds;
                [self.backgroundView _setCornerRadius: 0];
                for(id object in self.backgroundView.subviews){
                    ((UIView *)object).frame = self.bounds;
                    for(id layer in ((UIView *)object).layer.sublayers){
                        ((CALayer *)layer).frame = self.bounds;
                    }
                }
            } else self.notifEffectView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.55];
            if([self respondsToSelector:@selector(ntfDynamicColor:)] && self.ntfDynamicColor){
                self.backgroundColor = self.ntfDynamicColor;
            }
            self.notifEffectView.frame = self.bounds;
            self.notifEffectView.frameX = 0;
            self.notifEffectView.frameWidth = UIScreen.mainScreen.bounds.size.width;
            
            self.notifEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            if(!colorBannersEnabled){
                [self addSubview:self.notifEffectView];
                [self sendSubviewToBack:self.notifEffectView];
            }
        }
        
        self.frameWidth = UIScreen.mainScreen.bounds.size.width;
        
        if(!self.extendedView && enableXBanners){
            self.extendedView = [[UIView alloc] initWithFrame:self.bounds];
            self.extendedView.frameHeight += 32;
            [self.superview addSubview: self.extendedView];
        }
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        
        if (interfaceOrientation == UIDeviceOrientationPortrait) {
            if(enableXBanners && self.frameY != 32){
                self.notifEffectView.frame = self.extendedView.frame;
                [self.extendedView addSubview:self.notifEffectView];
                self.frameY = 32;
                [self.extendedView addSubview:self];
            }
        }
        
        if(!enableXBanners){
            self.frameY = -.5;
        }
        NSLog(@"nine_TWEAK | %li", (long)[[UIApplication sharedApplication] statusBarOrientation]);
        if (enableXBanners && (interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight)) {
            self.frameX = 25;
            self.notifEffectView.frameX = -25;
            self.frameWidth = UIScreen.mainScreen.bounds.size.width -25;
        } else self.frameX = 0;
        
        // enable built in grabber and coloring
        if(enableGrabber == YES){
            grabberView.pill.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:.6];
        }
        grabberView.hidden = enableGrabber ? NO : YES;

        if([self respondsToSelector:@selector(singleLine)]) self.singleLine.hidden = YES;
    } else if(!enableBannerSection){
        if(self.backgroundView){
            self.backgroundView.hidden = NO;
        }
        [[self backgroundMaterialView] setHidden:NO];
        MSHookIvar<MTMaterialView *>(self, "_mainOverlayView").hidden = NO;
        MSHookIvar<UIImageView *>(self, "_shadowView").hidden = NO;
        self.singleLine.hidden = YES;
        
        UIColor *black = [UIColor blackColor];
        
        [[self _headerContentView] setTintColor:black];
        [[[[self _headerContentView] _dateLabel] _layer] setFilters:nil];
        [[[[self _headerContentView] _titleLabel] _layer] setFilters:nil];
        if ([self.notificationContentView respondsToSelector:@selector(_summaryLabel)]){
            BSUIEmojiLabelView *fancyLabel = [self.notificationContentView _summaryLabel];
            [[[fancyLabel contentLabel] _layer] setFilters:nil];
        }
        [[[self _headerContentView] _dateLabel] setTextColor:black];
        [[[self _headerContentView] _titleLabel] setTextColor:black];
        [[self.notificationContentView _secondaryTextView] setTextColor:black];
        [[self.notificationContentView _primaryLabel] setTextColor:black];
        [[self.notificationContentView _primarySubtitleLabel] setTextColor:black];
        if ([self.notificationContentView respondsToSelector:@selector(_secondaryLabel)]) [[self.notificationContentView _secondaryLabel] setTextColor:black];
        if ([self.notificationContentView respondsToSelector:@selector(_summaryLabel)]) [[self.notificationContentView _summaryLabel] setTextColor:black];
    }
}
%new
-(void) handleNotification{
    NCNotificationGrabberView *grabberView = MSHookIvar<NCNotificationGrabberView *>(self, "_grabberView"); // Grabber used for later;
    
    if(enableNotifications){
        if(self.backgroundView){
            self.backgroundView.hidden = YES;
        }
        
        MSHookIvar<UIImageView *>(self, "_shadowView").hidden = YES;
        
        //Sets all text to white color
        UIColor *white = [UIColor whiteColor];
        
        [[self _headerContentView] setTintColor:white];
        [[[[self _headerContentView] _dateLabel] _layer] setFilters:nil];
        [[[[self _headerContentView] _titleLabel] _layer] setFilters:nil];
        if ([self.notificationContentView respondsToSelector:@selector(_summaryLabel)]){
            BSUIEmojiLabelView *fancyLabel = [self.notificationContentView _summaryLabel];
            [[[fancyLabel contentLabel] _layer] setFilters:nil];
        }
        
        [[[self _headerContentView] _dateLabel] setTextColor:white];
        [[[self _headerContentView] _titleLabel] setTextColor:white];
        [[self.notificationContentView _secondaryTextView] setTextColor:white];
        [[self.notificationContentView _primaryLabel] setTextColor:white];
        [[self.notificationContentView _primarySubtitleLabel] setTextColor:white];
        if ([self.notificationContentView respondsToSelector:@selector(_secondaryLabel)]) [[self.notificationContentView _secondaryLabel] setTextColor:white];
        if ([self.notificationContentView respondsToSelector:@selector(_summaryLabel)]) [[self.notificationContentView _summaryLabel] setTextColor:white];
        
        [[self backgroundMaterialView] setHidden:YES];
        MSHookIvar<MTMaterialView *>(self, "_mainOverlayView").hidden = true;
        
        self.notifEffectView.hidden = YES;
        
        UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

        if(!enableExtend || interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight){
            self.frameWidth = self.superview.frame.size.width - .5;
        } else {
            self.frameWidth = UIScreen.mainScreen.bounds.size.width - ((UIScreen.mainScreen.bounds.size.width - self.superview.frame.size.width) / 2);
        }
        
        if(enableSeparators){
            if(!self.topLine){
                
                self.topLine.drawsWithVibrantLightMode = NO;
                self.topLine = [[%c(_UITableViewCellSeparatorView) alloc] initWithFrame:self.frame];
                UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                UIVibrancyEffect *vibEffect = [UIVibrancyEffect effectForBlurEffect:effect];
                [self.topLine setSeparatorEffect:vibEffect];
                self.topLine.alpha = .45;
                
                [self addSubview:self.topLine];
                
            }
            self.topLine.frameHeight = .5;
            self.topLine.frameX = 12;
            
            if(!enableExtend || interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight){
                self.topLine.frameWidth = self.frame.size.width - 17;
            } else {
                self.topLine.frameWidth = self.frame.size.width - 12;
            }
            self.topLine.frameY = -7;
            
            [self tcUpdateTopLine];
            
            if(!self.singleLine){
                
                self.singleLine.drawsWithVibrantLightMode = NO;
                self.singleLine = [[%c(_UITableViewCellSeparatorView) alloc] initWithFrame:self.frame];
                UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
                UIVibrancyEffect *vibEffect = [UIVibrancyEffect effectForBlurEffect:effect];
                [self.singleLine setSeparatorEffect:vibEffect];
                self.singleLine.alpha = .45;
                
                [self addSubview:self.singleLine];
                
            }
            self.singleLine.frameHeight = .5;
            self.singleLine.frameX = 12;
            
            if(!enableExtend || interfaceOrientation == UIDeviceOrientationLandscapeLeft || interfaceOrientation == UIDeviceOrientationLandscapeRight){
                self.singleLine.frameWidth = self.frame.size.width - 17;
            } else {
                self.singleLine.frameWidth = self.frame.size.width - 12;
            }
            self.singleLine.frameY = 2 * self.center.y;
        }
    }
    grabberView.hidden = YES;
}

%new
-(void) tcUpdateTopLine{
    if([self._viewControllerForAncestor respondsToSelector:@selector(delegate)]){
        if([((NCNotificationCombinedListViewController *)((NCNotificationShortLookViewController *)self._viewControllerForAncestor)._parentViewController).notificationPriorityList.allNotificationRequests firstObject] == ((NCNotificationShortLookViewController *)self._viewControllerForAncestor).notificationRequest){
            self.topLine.alpha = 0;
            self.topLine.hidden = NO;
            [UIView animateWithDuration:.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{self.topLine.alpha = .45;}
                             completion:nil];
        } else {
            self.topLine.hidden = YES;
        }
    }
}
%end

%hook PLPlatterView
-(void) layoutSubviews{
    %orig;
    if(enableNotifications){
        NCNotificationViewControllerView *contView = (NCNotificationViewControllerView *)((NCNotificationShortLookViewController *)self._viewControllerForAncestor).view;
        if([contView isKindOfClass:%c(NCNotificationViewControllerView)]){
            if(!((NCNotificationShortLookView *)contView.contentView).isNineBanner || enableBannerSection){
                self.backgroundView.hidden = YES;
                self.overlayAlpha = 0;
                self.hasStackingShadow = NO;
            }
        }
    }
}
%end

%hook PLPlatterHeaderContentView // ios 12
-(void) layoutSubviews{
    if(enableExtend){
        NCNotificationViewControllerView *contView = (NCNotificationViewControllerView *)((NCNotificationShortLookViewController *)self._viewControllerForAncestor).view;
        if([contView isKindOfClass:%c(NCNotificationViewControllerView)]){
            ((UIView *)self).frameWidth = contView.contentView.frame.size.width;
        }
    }
    if(enableBannerSection){
        NCNotificationViewControllerView *contView = (NCNotificationViewControllerView *)((NCNotificationShortLookViewController *)self._viewControllerForAncestor).view;
        if([contView isKindOfClass:%c(NCNotificationViewControllerView)]){
            if(((NCNotificationShortLookView *)contView.contentView).isNineBanner){
                ((UIView *)self).frameWidth = contView.contentView.frame.size.width;
            }
        }
    }
    if(enableIconRemove == YES){
        ((UIButton *)self.iconButtons[0]).hidden = YES;
        
        CGRect headerFrame = ((UILabel *)[self _titleLabel]).frame;
        headerFrame.origin.x = -13;
        ((UILabel *)[self _titleLabel]).bounds = headerFrame;
        
    }
    %orig;
}
%end
%end // End ShortLookNotification.

%hook NCNotificationListSectionHeaderView
%property (nonatomic, retain) UIVisualEffectView *headerEffectView;
-(id)initWithFrame:(CGRect) frame{
    if((self = %orig)){
        if(enableHeaders){
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithBlurRadius:3];
            self.headerEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            self.headerEffectView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:.2];
            
            [self addSubview:self.headerEffectView];
            [self sendSubviewToBack: self.headerEffectView];
        }
    }
    return self;
}
-(void) _layoutHeaderTitleView{
    %orig;
    if(enableHeaders){
        self.headerEffectView.frame = self.bounds;
        [self insertSubview:self.headerEffectView belowSubview:self.headerTitleView];
    }
}
%end

%hook NCNotificationListCellActionButton
-(void) layoutSubviews{
    %orig;
    if(enableNotifications){
        MTMaterialView *materialView = MSHookIvar<MTMaterialView *>(self, "_backgroundView");
        MSHookIvar<MTMaterialView *>(materialView, "_backdropView").hidden = true;
        MSHookIvar<MTMaterialView *>(self, "_backgroundOverlayView").hidden = true;
        
        UILabel *label = MSHookIvar<UILabel *>(self, "_titleLabel");
        [label setTextColor:[UIColor whiteColor]];
        [[label _layer] setFilters:nil];
        MSHookIvar<UIView *>(self, "_backgroundHighlightView").alpha = 0;
    }
    
}
%end

%hook NCNotificationViewControllerView
-(void) layoutSubviews{
    if(![[self.contentView _viewControllerForAncestor] respondsToSelector:@selector(delegate)] || !enableBannerSection){
        %orig;
        return;
    }
    if([[[self.contentView _viewControllerForAncestor] delegate] isKindOfClass:%c(SBNotificationBannerDestination)]){
        CGRect frame = self.frame;
        frame.origin.y = 0;
        self.frame = frame;
    }
    %orig;
}
%end

// Posting all notifications :)

/*
%hookf(uint32_t, notify_post, const char *name) {
    uint32_t r = %orig;
    //if (strstr(name, "notification")) {
        NSLog(@"NOTI_MON: %s", name);
    //}
        return r;
}

%hookf(void, CFNotificationCenterPostNotification, CFNotificationCenterRef center, CFNotificationName name, const void *object, CFDictionaryRef userInfo, Boolean deliverImmediately) {
            %orig;
            NSString *notiName = (__bridge NSString *)name;
            //if ([notiName containsString:@"notification"]) {
                NSLog(@"NOTI_MON: %@", notiName);
            //}
}
 */
/*
%ctor{
 [[NSNotificationCenter defaultCenter] addObserverForName:NULL object:NULL queue:NULL usingBlock:^(NSNotification *note) {
 if ([note.name containsString:@"UIViewAnimationDidCommitNotification"] || [note.name containsString:@"UIViewAnimationDidStopNotification"] || [note.name containsString:@"UIScreenBrightnessDidChangeNotification"]){
 } else {
 NSLog(@"UNIQUE: %@", note.name);
 }
 }];
}
*/

/* // debugging
 @try {
 [superview addConstraints:@[ contentViewLeadingConstraint,
 contentViewTrailingConstraint, contentViewHeightConstraint, contentViewYConstraint]];
 } @catch (NSException *exception) {
 NSLog(@"nine_TWEAK %@",exception);
 @throw exception;
 }
 */

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
    
    #ifndef SIMULATOR
    HBPreferences *settings = [[HBPreferences alloc] initWithIdentifier:@"com.thecasle.nineprefs"];
    [settings registerDefaults:@{
        @"tweakEnabled": @YES,
        @"bannersEnabled": @NO,
        @"shadedEnabled": @YES,
        @"extendEnabled": @YES,
        @"grabberEnabled": @YES,
        @"iconRemoveEnabled": @NO,
        @"colorEnabled": @NO,
        @"bannerSectionEnabled": @YES,
        @"clearBackgroundEnabled": @YES,
        @"separatorsEnabled": @YES,
        @"notificationsEnabled": @YES,
        @"hideClockEnabled": @NO,
        @"hideTextEnabled":@NO,
    }];
    
    BOOL tweakEnabled = [settings boolForKey:@"tweakEnabled"];
    enableXBanners = [settings boolForKey:@"bannersEnabled"];
    enableHeaders = [settings boolForKey:@"shadedEnabled"];
    enableExtend = [settings boolForKey:@"extendEnabled"];
    enableGrabber = [settings boolForKey:@"grabberEnabled"];
    enableIconRemove = [settings boolForKey:@"iconRemoveEnabled"];
    enableBannerSection = [settings boolForKey:@"bannerSectionEnabled"];
    enableClearBackground = [settings boolForKey:@"clearBackgroundEnabled"];
    enableSeparators = [settings boolForKey:@"separatorsEnabled"];
    enableNotifications = [settings boolForKey:@"notificationsEnabled"];
    enableHideClock = [settings boolForKey:@"hideClockEnabled"];
    enableHideText = [settings boolForKey:@"hideTextEnabled"];
    #else
    BOOL tweakEnabled = YES;
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
    #endif
    
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("ch.mdaus.palette"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("com.golddavid.colorbanners2"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    

    if(tweakEnabled && SYSTEM_VERSION_12) {
        %init;
        %init(ShortLookGeneral);
        
    }
    /*
    [[NSNotificationCenter defaultCenter] addObserverForName:NULL object:NULL queue:NULL usingBlock:^(NSNotification *note) {
        if ([note.name containsString:@"UIViewAnimationDidCommitNotification"] || [note.name containsString:@"UIViewAnimationDidStopNotification"] || [note.name containsString:@"UIScreenBrightnessDidChangeNotification"]){
        } else {
            NSLog(@"UNIQUE: %@", note.name);
        }
    }];
    */
}

