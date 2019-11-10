#import <Cephei/HBPreferences.h>
#import <CepheiPrefs/HBRootListController.h>

@interface CLPRootListController : HBRootListController
@property (nonatomic, retain) UIImageView *iconView;
@property (nonatomic, retain) UIImageView *headerImage;
@property (nonatomic, retain) UIView *headerView;
@property (nonatomic, retain) UIView *headerCoverView;

@property (nonatomic, retain) UIImageView *headerImageView;

@property (nonatomic, retain) NSMutableArray<PSSpecifier *> *hiddenSpecifiers;

@end
