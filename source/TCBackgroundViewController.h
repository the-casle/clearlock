#import <Foundation/Foundation.h>
@interface BSUIBackdropView : UIView
@end
@interface TCBackgroundViewController : UIViewController
@property (nonatomic, retain) BSUIBackdropView *blurEffectView;
@property (nonatomic, retain) BSUIBackdropView *blurHistoryEffectView;
-(void) updateSceenShot: (BOOL)content isRevealed: (BOOL)isHistoryRevealed;
+ (id) sharedInstance;
@end
