include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = clearlockprefs
clearlockprefs_FILES = CLPRootListController.m
clearlockprefs_INSTALL_PATH = /Library/PreferenceBundles
clearlockprefs_FRAMEWORKS = UIKit
clearlockprefs_EXTRA_FRAMEWORKS = Cephei CepheiPrefs
clearlockprefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/clearlockprefs.plist$(ECHO_END)
