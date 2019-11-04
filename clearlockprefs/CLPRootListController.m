#include "CLPRootListController.h"
#import <CepheiPrefs/HBRootListController.h>
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <Cephei/HBPreferences.h>
#include <spawn.h>


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
    }

    return self;
}


- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}

	return _specifiers;
}




@end
