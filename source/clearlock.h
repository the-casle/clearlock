@interface SBLockStateAggregator
+(id) sharedInstance;
@end

@interface SBCoverSheetSlidingViewController
- (long long)dismissalSlidingMode;
@end

@interface SBWallpaperController
+(id)sharedInstance;
@property (assign,nonatomic) long long variant;
-(id)_wallpaperViewForVariant:(long long)arg1 ;
-()_window;
@property (nonatomic) CGFloat windowLevel;
@end

@interface SBCoverSheetUnlockedEnvironmentHostingViewController
@property (nonatomic,retain) UIView *maskingView;
@end

@interface SBDashBoardViewController : UIViewController
@end

@interface UIView (copy)
-(id) _viewDelegate;
@end

@interface SBHomeScreenWindow
-(void)_setSecure:(BOOL)arg1;
@end

@interface SBMainDisplaySceneLayoutWindow
-(void)_setSecure:(BOOL)arg1;
@end

@interface SBLockScreenManager
@property (nonatomic,readonly) SBDashBoardViewController * dashBoardViewController;
+(id)sharedInstance;
@end

@interface SBCoverSheetTransitionSettings
@property (assign,nonatomic) BOOL blursPanel;
@property (assign,nonatomic) double blurRadius;
@property (assign,nonatomic) double blurStart;
@property (assign,nonatomic) double blurEnd;
@property (assign,nonatomic) double blurEndReducedTransparency;
@property (assign,nonatomic) BOOL fadesContent;
@property (assign,nonatomic) double maxContentAlpha;
@property (assign,nonatomic) double contentFadeStart;
@property (assign,nonatomic) double contentFadeEnd;
@property (assign,nonatomic) BOOL darkensContent;
@property (assign,nonatomic) double darkeningColorWhite;
@property (assign,nonatomic) double darkeningColorAlpha;
@property (assign,nonatomic) double darkeningStart;
@property (assign,nonatomic) double darkeningEnd;
@property (assign,nonatomic) BOOL panelWallpaper;
@property (assign,nonatomic) BOOL trackingWallpaper;
@property (assign,nonatomic) double trackingWallpaperParallaxFactor;
@property (assign,nonatomic) BOOL revealWallpaper;
@property (assign,nonatomic) BOOL fadePanelWallpaper;
@property (assign,nonatomic) double fadePanelWallpaperStart;
@property (assign,nonatomic) double fadePanelWallpaperEnd;
@property (assign,nonatomic) BOOL iconsFlyIn;
@end
