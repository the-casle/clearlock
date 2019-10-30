#import <Foundation/Foundation.h>
@interface BSUIBackdropView : UIView
@end
@interface TCBackgroundViewController : UIViewController
@property (nonatomic, retain) BSUIBackdropView *blurEffectView;
@property (nonatomic, retain) BSUIBackdropView *blurHistoryEffectView;
@property (nonatomic, retain) UIImageView *snapshotImageView;
-(void) updateWithContent: (BOOL)content isHistoryRevealed: (BOOL)isHistoryRevealed;
+ (id) sharedInstance;
@end
