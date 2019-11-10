#include "CLPRootListController.h"
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#include <spawn.h>

@interface PSSpecifier
-(id)propertyForKey:(id)arg1 ;
@property (nonatomic,retain) NSArray * values;
@end

@implementation CLPRootListController

- (instancetype)init {
    self = [super init];





    if (self) {

		//[DarkMessagesTheme themeStuffInClasses:@[self.class]];
        HBAppearanceSettings *appearanceSettings = [[HBAppearanceSettings alloc] init];
        appearanceSettings.tintColor = [UIColor colorWithRed:0.96 green:0.60 blue:0.61 alpha:1.0];
        appearanceSettings.statusBarTintColor = [UIColor whiteColor];
        appearanceSettings.tableViewCellSeparatorColor = [UIColor colorWithWhite:0 alpha:0];
        appearanceSettings.navigationBarTitleColor = [UIColor whiteColor];
        appearanceSettings.navigationBarTintColor = [UIColor whiteColor];
        appearanceSettings.navigationBarBackgroundColor = [UIColor colorWithRed:0.96 green:0.60 blue:0.61 alpha:1.0];
        appearanceSettings.translucentNavigationBar = NO;
        appearanceSettings.tableViewCellTextColor = [UIColor colorWithRed:0.96 green:0.60 blue:0.61 alpha:1.0];
        appearanceSettings.tableViewCellSelectionColor = [UIColor colorWithRed:0.96 green:0.60 blue:0.61 alpha:1.0];
        appearanceSettings.tableViewCellBackgroundColor = [UIColor colorWithRed:1.00 green:1.00 blue:1.00 alpha:1.0];
        appearanceSettings.tableViewBackgroundColor = [UIColor colorWithRed:0.90 green:0.90 blue:0.90 alpha:1.0];
        self.hb_appearanceSettings = appearanceSettings;

        self.iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,10,10)];
        self.iconView.alpha = 1.0;
        
        self.hiddenSpecifiers = [[NSMutableArray alloc] init];
    }

    return self;
}


- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];

        PSSpecifier *managerSwitch = [self specifierForID:@"idTransparency"];
        if(!((NSNumber *)[self readPreferenceValue:managerSwitch]).boolValue){
            for(PSSpecifier *specifier in _specifiers){
                if([[specifier propertyForKey:@"id"] isEqualToString:@"idClearLockscreen"]){
                    [self.hiddenSpecifiers addObject:specifier];
                    [self removeSpecifier:specifier animated:YES];
                }
            }
        }
        
    }

	return _specifiers;
}


- (void)viewDidLoad {
    [super viewDidLoad];



    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 180)];
    self.headerCoverView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 200, 180)];
    self.headerCoverView.contentMode = UIViewContentModeScaleAspectFill;
    self.headerCoverView.translatesAutoresizingMaskIntoConstraints = NO;
    self.headerCoverView.backgroundColor = [UIColor colorWithRed:0.96 green:0.60 blue:0.61 alpha:1.0];
    [self.headerView addSubview:self.headerCoverView];


//         UIImage *eyeImage = [UIImage imageWithContentsOfFile:@"/Library/PreferenceBundles/InstallerPrefs.bundle/installer.png"];
//  CGFloat width = [UIScreen mainScreen].bounds.size.width;
//         self.headerImage = [[UIImageView alloc] initWithFrame:CGRectMake( ((width/2) - 75),(18),(150),(150))];
//         self.headerImage.image = eyeImage;


//         [self.headerView addSubview: self.headerImage];

    [NSLayoutConstraint activateConstraints:@[
        [self.headerCoverView.topAnchor constraintEqualToAnchor:self.headerView.topAnchor],
        [self.headerCoverView.leadingAnchor constraintEqualToAnchor:self.headerView.leadingAnchor],
        [self.headerCoverView.trailingAnchor constraintEqualToAnchor:self.headerView.trailingAnchor],
        [self.headerCoverView.bottomAnchor constraintEqualToAnchor:self.headerView.bottomAnchor],
    ]];




}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CGRect frame = self.table.bounds;
    frame.origin.y = -frame.size.height;


    self.navigationController.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.96 green:0.60 blue:0.61 alpha:1.0];
    [self.navigationController.navigationController.navigationBar setShadowImage: [UIImage new]];
    self.navigationController.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationController.navigationBar.translucent = NO;

}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    tableView.tableHeaderView = self.headerView;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    return [super tableView:tableView cellForRowAtIndexPath:indexPath];


}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;

    if (offsetY > 100) {
        [UIView animateWithDuration:0.2 animations:^{
            self.iconView.alpha = 0.0;
        }];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.iconView.alpha = 1.0;
        }];
    }
    
    if (offsetY > 0) offsetY = 0;
    self.headerCoverView.frame = CGRectMake(0, offsetY, self.headerView.frame.size.width, 180 - offsetY);
}
-(void)setPreferenceValue:(id)arg1 specifier:(PSSpecifier *)specifier{
    [super setPreferenceValue:arg1 specifier: specifier];

    if([[specifier propertyForKey:@"id"] isEqualToString:@"idTransparency"]){
        BOOL value = ((NSNumber *)arg1).boolValue;
        if(value){
            PSSpecifier *hiddenSpecifier = nil;
            for(PSSpecifier *specifier in self.hiddenSpecifiers){
                if([[specifier propertyForKey:@"id"] isEqualToString:@"idClearLockscreen"]) hiddenSpecifier = specifier;
            }
            [self insertSpecifier:hiddenSpecifier afterSpecifierID:@"idTransparency" animated:YES];
        } else {
            PSSpecifier *specifier = [self specifierForID:@"idClearLockscreen"];
            [self.hiddenSpecifiers addObject:specifier];
            [self removeSpecifier:specifier animated:YES];
        }
    }
}
@end
