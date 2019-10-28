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

