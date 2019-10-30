export ARCHS = arm64 arm64e
export TARGET = iphone:clang:11.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = clearlock
clearlock_FILES = $(wildcard source/*.m source/*.xm source/*.mm source/*.x)
clearlock_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
clearlock_CFLAGS += -fobjc-arc -I$(THEOS_PROJECT_DIR)/source

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
