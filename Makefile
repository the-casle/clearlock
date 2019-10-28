export ARCHS = arm64 arm64e
export TARGET = iphone:clang:11.2:10.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = nine12
nine12_FILES = $(wildcard source/*.m source/*.xm source/*.mm source/*.x)
nine12_CFLAGS += -fobjc-arc -I$(THEOS_PROJECT_DIR)/source

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
