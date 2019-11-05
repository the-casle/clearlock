export ARCHS = arm64 arm64e
export TARGET = iphone:clang:11.2:10.0
export THEOS_DEVICE_IP=172.17.12.233


include $(THEOS)/makefiles/common.mk

TWEAK_NAME = clearlock
clearlock_FILES = $(wildcard source/*.m source/*.xm source/*.mm source/*.x)
clearlock_EXTRA_FRAMEWORKS += Cephei
clearlock_CFLAGS += -fobjc-arc -I$(THEOS_PROJECT_DIR)/source

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += clearlockprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
